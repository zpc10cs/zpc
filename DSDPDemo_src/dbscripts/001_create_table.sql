-- Create table
create table DSDPDEMO_T_ITEM
(
   ITEMID              NUMBER(13)          not null,
   ITEMNAME            VARCHAR2(32 char)   not null,
   ITEMPRICE           NUMBER(20,4)        not null,
   CREATETIME          TIMESTAMP,
   LASTUPDATETIME      TIMESTAMP,
   constraint PK_DSDPDEMO_T_ITEM primary key (ITEMID)
);