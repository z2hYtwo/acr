import uuid
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException
from starlette.responses import JSONResponse
from app.core.config import Settings
from app.core.auth import valid_token
from app.api.health import router

def create_app() -> FastAPI:
    settings = Settings()
    app = FastAPI(title="AI Comic Studio Internal AI API", version="0.1.0", docs_url=None, redoc_url=None, openapi_url=None)
    @app.middleware("http")
    async def internal_auth(request: Request, call_next):
        request_id = str(uuid.uuid4())
        if request.url.path.startswith("/internal/") and not valid_token(request.headers.get("Authorization", ""), settings.ai_engine_token.get_secret_value()):
            response = JSONResponse(status_code=401, content={"code":"UNAUTHORIZED","message":"Internal authentication required","data":None}, headers={"WWW-Authenticate":"Bearer"})
        else:
            response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response
    @app.exception_handler(HTTPException)
    async def http_error(request: Request, exc: HTTPException):
        code = "NOT_FOUND" if exc.status_code == 404 else "INTERNAL_ERROR"
        return JSONResponse(status_code=exc.status_code, content={"code":code,"message":"Not found" if exc.status_code == 404 else "Request failed","data":None})
    @app.exception_handler(RequestValidationError)
    async def validation_error(request: Request, exc: RequestValidationError):
        return JSONResponse(status_code=422, content={"code":"VALIDATION_ERROR","message":"Invalid request","data":None})
    @app.exception_handler(Exception)
    async def internal_error(request: Request, exc: Exception):
        return JSONResponse(status_code=500, content={"code":"INTERNAL_ERROR","message":"Internal server error","data":None})
    app.include_router(router)
    return app
