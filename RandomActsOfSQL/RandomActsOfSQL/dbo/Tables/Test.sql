CREATE TABLE [dbo].[Test] (
    [TestId]   INT            IDENTITY (1, 1) NOT NULL,
    [JsonTest] NVARCHAR (MAX) NULL,
    CONSTRAINT [chk_is_json] CHECK (isjson([JsonTest])=(1))
);

