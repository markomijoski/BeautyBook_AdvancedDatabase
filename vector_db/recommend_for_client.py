from sentence_transformers import SentenceTransformer
import psycopg2
import numpy as np

model = SentenceTransformer('all-MiniLM-L6-v2')

conn = psycopg2.connect(
    host="localhost",
    port="5432",
    database="your_db_name",
    user="your_db_user",
    password="your_password"
)

cur = conn.cursor()

client_id = input("Enter client_id: ")

# =========================
# 1. GET CLIENT HISTORY
# =========================
cur.execute("""
    SELECT s.embedding
    FROM appointment a
    JOIN appointment_service aps
        ON a.appointment_id = aps.appointment_id
    JOIN service s
        ON aps.service_id = s.service_id
    WHERE a.client_id = %s
""", (client_id,))

history = cur.fetchall()

if not history:
    print("No history found for this client. Using cold-start mode.")

    # fallback: generic query vector
    user_query = input("What are you looking for? ")
    client_vector = model.encode(user_query)

else:
    # =========================
    # 2. BUILD USER PROFILE VECTOR
    # =========================
    embeddings = [np.array(row[0]) for row in history]
    client_vector = np.mean(embeddings, axis=0)

# =========================
# 3. FETCH ALL SERVICES
# =========================
cur.execute("""
    SELECT
        s.service_id,
        s.service_name,
        sc.category_name,
        s.price,
        s.embedding,
        s.avg_rating,
        s.popularity
    FROM service s
    JOIN service_category sc
        ON s.service_category_id = sc.service_category_id
    WHERE s.embedding IS NOT NULL
""")

rows = cur.fetchall()

service_embeddings = np.array([r[4] for r in rows])

# =========================
# 4. VECTORIZED SIMILARITY
# =========================
norms = np.linalg.norm(service_embeddings, axis=1) * np.linalg.norm(client_vector)

similarities = (service_embeddings @ client_vector) / norms

# =========================
# 5. SCORING
# =========================
results = []

for i, row in enumerate(rows):

    service_id, name, category, price, _, rating, popularity = row

    rating_score = rating / 5
    popularity_score = min(popularity / 50, 1)

    final_score = (
        similarities[i] * 0.75 +
        rating_score * 0.15 +
        popularity_score * 0.10
    )

    results.append({
        "service": name,
        "category": category,
        "price": price,
        "score": final_score
    })

# =========================
# 6. SORT + FILTER
# =========================
results.sort(key=lambda x: x["score"], reverse=True)

seen = set()

print("\nPersonalized recommendations:\n")

count = 0

for r in results:

    if r["service"] in seen:
        continue

    seen.add(r["service"])

    print(
        f"{r['service']} | {r['category']} | {r['price']} | Score: {r['score']:.3f}"
    )

    count += 1
    if count == 5:
        break

cur.close()
conn.close()