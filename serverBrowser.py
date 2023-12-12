from __future__ import annotations

from flask import Flask, request
import logging
import sys
from typing import Union
import time
import numpy as np
from dataclasses import dataclass, field
from apscheduler.schedulers.background import BackgroundScheduler
import atexit

app = Flask(__name__)

serverdict: dict[str, ServerEntry] = {}
SERVERTIMEOUTFACTOR: float = 5.0
HOST_IP: str = "127.0.0.1"#"45.84.138.205"
HOST_PORT: int = 5000
DEBUG: bool = True
disableRequestLogging: bool = True


@dataclass
class ServerEntry:
    ip: str
    maxUpdateTimesStored: int = 10
    lastUpdatesReceived: np.ndarray = np.empty(0)

    def get_default_request_interval(self) -> float:
        interval: float = float(np.inf)
        if len(self.lastUpdatesReceived) > 1:
            interval: float = float(np.mean(np.diff(self.lastUpdatesReceived)))
        return interval

    def get_time_of_last_update(self) -> float:
        return self.lastUpdatesReceived[-1]

    def add_update_time(self, t: float) -> None:
        if self.lastUpdatesReceived is None:
            self.lastUpdatesReceived = np.array([t])
        elif len(self.lastUpdatesReceived) < self.maxUpdateTimesStored:
            self.lastUpdatesReceived = np.append(self.lastUpdatesReceived, np.array([t]))
        else:
            self.lastUpdatesReceived[:-1] = self.lastUpdatesReceived[1:]  # shift all but the last entries one index back
            self.lastUpdatesReceived[-1] = t  # add new time to the last index


def check_server_times() -> None:
    servers_to_remove = []
    curTime: float = time.time()
    for ip, server in serverdict.items():
        delta: float = curTime - server.get_time_of_last_update()
        max_delta: float = server.get_default_request_interval() * SERVERTIMEOUTFACTOR
        if delta > max_delta:
            servers_to_remove.append(ip)

    for ip in servers_to_remove:
        logger.info(f"Timeout of server {ip}")
        del serverdict[ip]


@app.route('/')
def check_availability() -> str:
    return "OK"


@app.route("/set_server")
def set_server() -> str:
    ip = request.remote_addr
    if ip not in serverdict:
        logger.info(f"Adding new Server: {ip}")
        serverdict[ip] = ServerEntry(ip)

    serverdict[ip].add_update_time(time.time())
    return "OK"


@app.route("/get_server_list")
def get_server_list():
    return [server.ip for server in serverdict.values()]


@app.route("/get_own_ip")
def get_own_public_ip() -> str:
    return request.remote_addr


def get_server_scheduler() -> BackgroundScheduler:
    scheduler: BackgroundScheduler = BackgroundScheduler()
    scheduler.add_job(func=check_server_times, trigger="interval", seconds=0.5)

    # Shut down the scheduler when exiting the app
    atexit.register(lambda: scheduler.shutdown())
    return scheduler


if __name__ == '__main__':
    serverCheckScheduler: BackgroundScheduler = get_server_scheduler()
    serverCheckScheduler.start()

    logger: logging.Logger = logging.getLogger("ServerBrowser")
    logger.addHandler(logging.StreamHandler(sys.stdout))
    logger.setLevel(logging.INFO)

    logging.basicConfig(format='%(asctime)s %(message)s')

    if disableRequestLogging:
        logging.getLogger("werkzeug").disabled = True

    logger.info("Starting ServerBrowser")
    app.run(host=HOST_IP, port=HOST_PORT, debug=DEBUG)
