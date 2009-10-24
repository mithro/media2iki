<xsl:stylesheet
   xmlns="http://www.mediawiki.org/xml/export-0.3/"
   xmlns:mw="http://www.mediawiki.org/xml/export-0.3/"
   exclude-result-prefixes="mw"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

<xsl:template match="mw:mediawiki">
  <xsl:copy>
  <xsl:apply-templates>
   <xsl:sort select="substring(mw:timestamp,1,4)"/>
   <xsl:sort select="substring(mw:timestamp,6,2)"/>
   <xsl:sort select="substring(mw:timestamp,9,2)"/>
   <xsl:sort select="substring(mw:timestamp,12,2)"/>
   <xsl:sort select="substring(mw:timestamp,15,2)"/>
   <xsl:sort select="substring(mw:timestamp,18,2)"/>
  </xsl:apply-templates>
  </xsl:copy>
</xsl:template>

<!-- uncomment this to make sure the dates are being sorted correctly
<xsl:template match="mw:revision">
<xsl:value-of select="mw:id"/>: <xsl:value-of select="substring(mw:timestamp,1,4)"/> - <xsl:value-of select="substring(mw:timestamp,6,2)"/> - <xsl:value-of select="substring(mw:timestamp,9,2)"/> T <xsl:value-of select="substring(mw:timestamp,12,2)"/> : <xsl:value-of select="substring(mw:timestamp,15,2)"/> : <xsl:value-of select="substring(mw:timestamp,18,2)"/>
<xsl:text>
</xsl:text>
</xsl:template>
-->

<xsl:template match="*|@*|text()">
  <xsl:copy>
    <xsl:apply-templates select="*|@*|text()"/>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
