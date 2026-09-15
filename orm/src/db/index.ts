import "dotenv/config";

import { createPool } from "mysql2";
import { drizzle } from "drizzle-orm/mysql2";

import { relations } from "./relations";

const databaseUrl = process.env.APP_DATABASE_URL;

if (!databaseUrl) {
    throw new Error("APP_DATABASE_URL nao definida.");
}

export const pool = createPool(databaseUrl);

export const db = drizzle({
    client: pool,
    relations,
});