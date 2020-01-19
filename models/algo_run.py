import json


class AlgoRun:
    def __init__(
        self, name: str, environment: str, build: str, parameters: dict
    ):
        self.name = name
        self.environment = environment
        self.build = build
        self.parameters = parameters
        self.algo_run_id = None

    async def save(self, db_connection):
        async with db_connection.transaction():
            self.algo_run_id = await db_connection.fetchval(
                """
                    INSERT INTO algo_run (algo_name, algo_env, build_number, parameters)
                    VALUES ($1, $2, $3, $4)
                    RETURNING algo_run_id
                """,
                self.name,
                self.environment,
                self.build,
                json.dumps(self.parameters),
            )

    async def update_end_time(self, db_connection):
        async with db_connection.transaction():
            self.algo_run_id = await db_connection.fetchval(
                """
                    UPDATE algo_run SET end_time = 'now()'
                    WHERE algo_run_id = $1
                """,
                self.algo_run_id,
            )