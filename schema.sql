-- ----------------------------
-- Table structure for "public"."deal"
-- ----------------------------
DROP TABLE "public"."deal";
CREATE TABLE "public"."deal" (
"id" int8 NOT NULL,
"size" numeric(20,15) NOT NULL,
"price" numeric(20,15) NOT NULL,
"orderBuyId" int8 NOT NULL,
"orderSellId" int8 NOT NULL,
"createdAt" int8 NOT NULL,
"userBuyId" int8 NOT NULL,
"userSellId" int8 NOT NULL,
"buyerFee" numeric(20,15) NOT NULL,
"sellerFee" numeric(20,15) NOT NULL,
"side" bool NOT NULL,
"currency" varchar(6)
)
WITH (OIDS=FALSE)

;

-- ----------------------------
-- Table structure for "public"."order"
-- ----------------------------
DROP TABLE "public"."order";
CREATE TABLE "public"."order" (
"id" int8 NOT NULL,
"userId" int8 NOT NULL,
"size" numeric(20,15) NOT NULL,
"actualSize" numeric(20,15) NOT NULL,
"price" numeric(20,15),
"createdAt" int8 NOT NULL,
"updatedAt" int8,
"status" varchar(40) NOT NULL,
"type" varchar(20) NOT NULL,
"side" bool NOT NULL,
"offset" numeric(20,15),
"currency" varchar(6)
)
WITH (OIDS=FALSE)

;
-- ----------------------------
-- Primary Key structure for table "public"."deal"
-- ----------------------------
ALTER TABLE "public"."deal" ADD PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table "public"."order"
-- ----------------------------
ALTER TABLE "public"."order" ADD PRIMARY KEY ("id");
