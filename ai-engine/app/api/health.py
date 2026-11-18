from fastapi import APIRouter, Depends
from app.core.auth import bearer
from app.schemas.common import ApiResponse, HealthData
router = APIRouter(prefix="/internal/v1", dependencies=[Depends(bearer)])
@router.get("/health", response_model=ApiResponse[HealthData], operation_id="aiHealth")
def health():
    return ApiResponse(code="OK", message="ok", data=HealthData(service="ai-engine", status="UP"))
