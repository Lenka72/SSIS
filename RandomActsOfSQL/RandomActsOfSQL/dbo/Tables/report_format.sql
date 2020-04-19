CREATE TABLE [dbo].[report_format] (
    [ReportFormatId]  INT          IDENTITY (1, 1) NOT NULL,
    [StyleName]       VARCHAR (25) NOT NULL,
    [FontFamily]      VARCHAR (50) NOT NULL,
    [FontSize]        VARCHAR (5)  NOT NULL,
    [FontWeight]      BIT          CONSTRAINT [DF_report_format_FontWeight] DEFAULT ((0)) NOT NULL,
    [BackgroundColor] VARCHAR (10) NULL,
    [FontColor]       VARCHAR (10) NULL,
    CONSTRAINT [PK_report_format] PRIMARY KEY CLUSTERED ([ReportFormatId] ASC)
);

