from motor.motor_asyncio import AsyncIOMotorClient
from app.config import settings

client = None
database = None


class Database:
    client: AsyncIOMotorClient = None
    database = None

    async def connect(self):
        try:
            self.client = AsyncIOMotorClient(settings.mongodb_url)
            self.database = self.client[settings.database_name]
            # Test connection
            await self.client.admin.command('ping')
            print(f"Connected to MongoDB: {settings.database_name}")
        except Exception as e:
            print(f"Error connecting to MongoDB: {e}")
            raise

    async def disconnect(self):
        if self.client:
            self.client.close()
            print("Disconnected from MongoDB")

    def get_collection(self, collection_name: str):
        if self.database is None:
            raise Exception("Database not connected. Call connect() first.")
        return self.database[collection_name]


database = Database()
