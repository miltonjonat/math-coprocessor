from os import environ
from asteval import Interpreter
from eth_abi import encode
import logging
import requests
import math
import numpy as np

logging.basicConfig(level="INFO")
logger = logging.getLogger(__name__)

rollup_server = environ["ROLLUP_HTTP_SERVER_URL"]
logger.info(f"HTTP rollup_server url is {rollup_server}")

aeval = Interpreter()
aeval.symtable["encode"] = encode
aeval.symtable["np"] = np
aeval.symtable["math"] = math
aeval.symtable["round"] = round

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
        # retrieve and decode input expression
        expr_hex = data['payload']
        expr = bytes.fromhex(expr_hex[2:]).decode('utf-8')
        print(f"input: {expr}")

        # evaluate expression
        result = aeval(expr)
        print(f"result: {result}")

        # handle integer types
        if isinstance(result, (int, np.integer)):
            result = encode(["int256"], [int(result)])

        # handle numpy integer array types
        elif isinstance(result, np.ndarray):
            if np.issubdtype(result.dtype, np.integer):
                abi_type = "int256" + "".join(f"[{dim}]" for dim in result.shape)
                result = encode([abi_type], [result.tolist()])

        if isinstance(result, bytes):
            # emit notice with hex-encoded bytes result
            emit_notice({"payload": f"0x{result.hex()}"})
            return "accept"
        else:
            # error: result must be a bytes object
            print(f"Error: expression result should be an integer, a NumPy integer ndarray, or an ABI-encoded bytes object")
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
