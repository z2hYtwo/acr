from typing import Generic, TypeVar
from pydantic import BaseModel
T = TypeVar("T")
class ApiResponse(BaseModel, Generic[T]):
    code: str
    message: str
    data: T | None = None
class HealthData(BaseModel):
    service: str
    status: str
