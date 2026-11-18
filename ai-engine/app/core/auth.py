import secrets
from fastapi.security import HTTPBearer

bearer = HTTPBearer(auto_error=False, scheme_name="InternalBearer")

def valid_token(header: str, token: str) -> bool:
    return secrets.compare_digest(header.encode("utf-8"), ("Bearer " + token).encode("utf-8"))
