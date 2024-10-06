module.exports = class Data1715436216627 {
    name = 'Data1715436216627'

    async up(db) {
        await db.query(`CREATE TABLE "burn" ("id" character varying NOT NULL, "block_number" integer NOT NULL, "timestamp" TIMESTAMP WITH TIME ZONE NOT NULL, "amount" numeric NOT NULL, "aggregated" numeric NOT NULL, CONSTRAINT "PK_dcb4f14ee4534154b31116553f0" PRIMARY KEY ("id"))`)
        await db.query(`CREATE INDEX "IDX_256979d718b3d192ec491aa210" ON "burn" ("block_number") `)
        await db.query(`CREATE INDEX "IDX_51879159280bddc67fbdbd9df9" ON "burn" ("timestamp") `)
    }

    async down(db) {
        await db.query(`DROP TABLE "burn"`)
        await db.query(`DROP INDEX "public"."IDX_256979d718b3d192ec491aa210"`)
        await db.query(`DROP INDEX "public"."IDX_51879159280bddc67fbdbd9df9"`)
    }
}
