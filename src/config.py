# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

import json
import logging
import os
from azure.monitor.opentelemetry import configure_azure_monitor
import yaml

logger = logging.getLogger(__name__)


def load_agent_config(scenario: str) -> dict:
    src_dir = os.path.dirname(os.path.abspath(__file__))
    scenario_directory = os.path.join(src_dir, f"scenarios/{scenario}/config")

    agent_config_path = os.path.join(scenario_directory, "agents.yaml")

    with open(agent_config_path, "r", encoding="utf-8") as f:
        agent_config = yaml.safe_load(f)
    bot_ids = json.loads(os.getenv("BOT_IDS"))
    hls_model_endpoints = json.loads(os.getenv("HLS_MODEL_ENDPOINTS"))
    for agent in agent_config:
        agent["bot_id"] = bot_ids.get(agent["name"])
        agent["hls_model_endpoint"] = hls_model_endpoints
        if agent.get("addition_instructions"):
            for file in agent["addition_instructions"]:
                with open(os.path.join(scenario_directory, file)) as f:
                    agent["instructions"] += f.read()

    return agent_config


def setup_logging(log_level=logging.DEBUG) -> None:
    # Set up console logging and ensure logs are propagated to root logger for Azure Monitor
    console_handler = logging.StreamHandler()
    logger = logging.getLogger(__name__)
    
    # Configure Azure Monitor if connection string is set
    if os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING"):
        configure_azure_monitor(
            connection_string=os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING"),
            logging_exporter_enabled=True,
            tracing_exporter_enabled=True,
            metrics_exporter_enabled=True,
            enable_live_metrics=True,
            formatter=logging.Formatter(
                "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            )
        )


    # Avoid duplicate handlers
    if not any(isinstance(h, logging.StreamHandler) for h in logger.handlers):
        logger.addHandler(console_handler)
    logger.setLevel(log_level)

    # Ensure all loggers propagate to root for Azure Monitor
    for name in logging.root.manager.loggerDict:
        logging.getLogger(name).propagate = True

class DefaultConfig:
    """ Bot Configuration """

    def __init__(self, botId):
        self.APP_ID = botId
        self.APP_PASSWORD = os.environ.get("MicrosoftAppPassword", "")
        self.APP_TYPE = os.environ.get("MicrosoftAppType", "MultiTenant")
        self.APP_TENANTID = os.environ.get("MicrosoftAppTenantId", "")
