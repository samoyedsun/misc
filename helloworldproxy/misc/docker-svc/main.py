from starlette.applications import Starlette
from starlette.responses import JSONResponse
from logic import Logic
import uvicorn, json

app = Starlette()

'''
curl -X POST -H 'Content-json' "http://localhost:8000/" -d '{"Id":"sha256"}'
curl -X POST -H 'Content-json' "http://localhost:8000/api/create" -d '{"port":30000,"instance":1,"ss_pass":"hello","ss_mode":"aes-256-cfb"}'
curl -X POST -H 'Content-json' "http://localhost:8000/api/remove" -d '{"port":30000,"instance":1}'
'''

@app.route("/", methods=["POST"])
async def homepage(request):
    print(request.method)
    print(request.headers["content-type"])
    print(request.url)
    msg = await request.json()
    print(msg)
    print(msg["Id"])
    print(type(msg["Id"]))
    return JSONResponse({"hello": "world"})

@app.route("/api/create", methods=["POST"])
async def api_create(request):
    msg = await request.json()
    Logic().serviceStart(port=msg["port"], instance=msg["instance"], ss_pass=msg["ss_pass"], ss_mode=msg["ss_mode"])
    return JSONResponse({"message": "create ok!"})

@app.route("/api/remove", methods=["POST"])
async def api_remove(request):
    msg = await request.json()
    Logic().serviceStop(port=msg["port"], instance=msg["instance"])
    return JSONResponse({"message": "remove ok!"})

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)