from os import environ
from asteval import Interpreter
import logging
import requests

logging.basicConfig(level="INFO")
logger = logging.getLogger(__name__)

rollup_server = environ["ROLLUP_HTTP_SERVER_URL"]
logger.info(f"HTTP rollup_server url is {rollup_server}")

aeval = Interpreter()

def emit_notice(data):
    notice_payload = {"payload": data["payload"]}
    response = requests.post(rollup_server + "/notice", json=notice_payload)
    if response.status_code == 200 or response.status_code == 201:
        logger.info(f"Notice emitted successfully with data: {data}")
    else:
        logger.error(f"Failed to emit notice with data: {data}. Status code: {response.status_code}")

def handle_advance(data):
    logger.info(f"Received advance request data {data}")
    try:
        expr_hex = data['payload']
        expr = bytes.fromhex(expr_hex[2:]).decode('utf-8')
        print(f"input: {expr}")
        result = aeval(expr)
        print(f"result: {result}")
        if isinstance(result, float):
            result = round(result)
            print(f"result (rounded): {result}")
        if isinstance(result, int):
            if result < 0:
                result = result & ((1 << 256) -1)
                print(f"result (as uint using 2-completion repr): {result}")
            result_hex = f"0x{result:064x}"
            emit_notice({'payload': result_hex})
            return "accept"
        else:
            print(f"Error: result is not a number")
            return "reject"
    
    except Exception as error:
        print(f"Error processing payload: {error}")
        return "reject"

def handle_inspect(data):
    logger.info(f"Received inspect request data {data}")
    return "accept"


handlers = {
    "advance_state": handle_advance,
    "inspect_state": handle_inspect,
}

finish = {"status": "accept"}

while True:
    logger.info("Sending finish")
    response = requests.post(rollup_server + "/finish", json=finish)
    logger.info(f"Received finish status {response.status_code}")
    if response.status_code == 202:
        logger.info("No pending rollup request, trying again")
    else:
        rollup_request = response.json()
        data = rollup_request["data"]
        handler = handlers[rollup_request["request_type"]]
        finish["status"] = handler(rollup_request["data"])
