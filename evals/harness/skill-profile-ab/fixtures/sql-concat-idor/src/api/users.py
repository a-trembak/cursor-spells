# Intentionally vulnerable user lookup for skill-profile A/B (do not ship).

def get_user(db, user_id: str):
    # SQL built by string concatenation from request input (S1 / injection).
    q = "SELECT * FROM users WHERE id = '" + user_id + "'"
    return db.execute(q)


def get_user_profile(db, user_id: str, requester_id: str):
    # No ownership check — any requester can fetch any user_id (IDOR / S2).
    return get_user(db, user_id)
