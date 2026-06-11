from sentence_transformers import SentenceTransformer
import psycopg2

model = SentenceTransformer('all-MiniLM-L6-v2')

conn = psycopg2.connect(
    host="localhost",
    port="5432",
    database="your_db_name",
    user="your_db_user",
    password="your_password"
)

cur = conn.cursor()

query="""
SELECT
    s.service_name,
    sc.category_name,
    s.price,
    s.duration_minutes
FROM service s
JOIN service_category sc
ON s.service_category_id=sc.service_category_id
"""

cur.execute(query)

services=cur.fetchall()

for service in services:

    service_id=service[0]
    name=service[1]
    category=service[2]
    price=service[3]
    duration=service[4]

    keywords=[]

    name_lower=name.lower()
    category_lower=category.lower()

    if "facial" in name_lower or "skin" in category_lower:
        keywords.extend([
            "skin care",
            "dry skin",
            "hydration",
            "face treatment",
            "healthy skin"
        ])

    if "hair" in category_lower:
        keywords.extend([
            "hair styling",
            "hair care",
            "hair treatment"
        ])

    if "nail" in category_lower:
        keywords.extend([
            "manicure",
            "pedicure",
            "nail care"
        ])

    text=f"""
    Service: {name}
    Category: {category}
    Price: {price}
    Duration: {duration}
    Keywords: {' '.join(keywords)}
    """

    embedding=model.encode(text).tolist()

    cur.execute(
        """
        UPDATE service
        SET embedding=%s
        WHERE service_id=%s
        """,
        (embedding,service_id)
    )

conn.commit()

cur.close()
conn.close()

print("Embeddings regenerated")