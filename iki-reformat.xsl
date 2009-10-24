<xsl:stylesheet
   xmlns="http://www.mediawiki.org/xml/export-0.3/"
   xmlns:mw="http://www.mediawiki.org/xml/export-0.3/"
   exclude-result-prefixes="mw"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

<xsl:template match="mw:page">
  <xsl:apply-templates select="mw:revision"/>
</xsl:template>

<xsl:template match="mw:revision">
  <revision>
  <xsl:apply-templates select="../mw:title"/>
  <xsl:apply-templates/>
  </revision>
</xsl:template>

<xsl:template match="*|@*|text()">
  <xsl:copy>
    <xsl:apply-templates select="*|@*|text()"/>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
