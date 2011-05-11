<?xml version="1.0" encoding="utf-8"?>
<!-- 
	XSLT for wiki2xml

	usage: /usr/bin/xsltproc xhtml.xslt yourfile.xml

	Given a wiki syntax article, use wiki2xml by Magnus Manke to convert it
	as a XML document. Save the XML in a file (ex: yourfile.xml) then launch
	xlstproc that will happylly apply this stylesheet to the xml document
	and output some XHTML.


	Author:
		Ashar Voultoiz <hashar@altern.org
	License:
	http://www.gnu.org/copyleft/gpl.html GNU General Public Licence 2.0 or later

	Copyright © 2006 Ashar Voultoiz

-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
	method="html" indent="yes"
	encoding="utf-8"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
/>

<xsl:template match="/">
	<xsl:apply-templates />
</xsl:template>

<xsl:template match="/articles">
	<xsl:apply-templates />
</xsl:template>

<xsl:template match="article">
<html>
<head>
	<title><xsl:value-of select="@title" /></title>
	<style type="text/css" media="screen">@import "http://en.wikipedia.org/w/skins-1.5/monobook/main.css";</style>
</head>
<body class="ns-0 ltr">
		<xsl:apply-templates />
</body>
</html>
</xsl:template>

<xsl:template match="heading">
	<xsl:choose>
		<xsl:when test="@level = 1">
		<h1><xsl:apply-templates/></h1>
		</xsl:when>
		<xsl:when test="@level = 2">
		<h2><xsl:apply-templates/></h2>
		</xsl:when>
		<xsl:when test="@level = 3">
		<h3><xsl:apply-templates/></h3>
		</xsl:when>
		<xsl:when test="@level = 4">
		<h4><xsl:apply-templates/></h4>
		</xsl:when>
		<xsl:when test="@level = 5">
		<h5><xsl:apply-templates/></h5>
		</xsl:when>
	</xsl:choose>
</xsl:template>

<xsl:template match="preline">
	<pre><xsl:apply-templates /></pre>
</xsl:template>
<xsl:template match="paragraph">
	<p><xsl:apply-templates /></p>
</xsl:template>

<xsl:template match="list">
	<xsl:choose>
		<xsl:when test="@type = numbered">
		<ol><xsl:apply-templates/></ol>
		</xsl:when>
		<xsl:when test="@type = bullet">
		<ul><xsl:apply-templates/></ul>
		</xsl:when>
		<xsl:when test="@type = def">
		<dl><xsl:apply-templates/></dl>
		</xsl:when>
		<xsl:when test="@type = ident">
		<dl><xsl:apply-templates/></dl>
		</xsl:when>
		<xsl:otherwise>
		<ul><xsl:apply-templates/></ul>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="tr">
<tr><xsl:apply-templates /></tr>
</xsl:template>

<xsl:template match="th">
<th><xsl:apply-templates /></th>
</xsl:template>

<xsl:template match="td">
<td><xsl:apply-templates /></td>
</xsl:template>

<xsl:template match="caption">
<caption><xsl:apply-templates /></caption>
</xsl:template>

<xsl:template match="table">
<table><xsl:apply-templates /></table>
</xsl:template>

<xsl:template match="tablerow">
<tr><xsl:apply-templates /></tr>
</xsl:template>

<xsl:template match="tablehead">
<th><xsl:apply-templates /></th>
</xsl:template>

<xsl:template match="tablecell">
<td><xsl:apply-templates /></td>
</xsl:template>

<xsl:template match="listitem">
<li><xsl:apply-templates /></li>
</xsl:template>

<xsl:template match="space">
<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text><xsl:apply-templates />
</xsl:template>

<xsl:template match="italics">
<i><xsl:apply-templates /></i>
</xsl:template>

<xsl:template match="link">
	<xsl:choose>
		<xsl:when test="@type='external'" >
			<xsl:text disable-output-escaping="yes">&lt;a href="</xsl:text><xsl:value-of select="@href" />
			<xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text disable-output-escaping="yes">&lt;a href="/</xsl:text>
			<xsl:apply-templates select="target"/>
			<xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
			<xsl:choose>
				<xsl:when test="child::part">
					<xsl:apply-templates select="part"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="target"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>
<xsl:template match="image">
                      <xsl:text disable-output-escaping="yes">&lt;img src="/</xsl:text>
                      <xsl:apply-templates select="source"/>
                      <xsl:text disable-output-escaping="yes">" styles="</xsl:text>
                        <xsl:for-each select="child::part[position()&lt;last()]">
                          <xsl:apply-templates />
                          <xsl:text disable-output-escaping="yes"> </xsl:text>
                        </xsl:for-each>
                      <xsl:text disable-output-escaping="yes">" alt="</xsl:text>
                        <xsl:for-each select="child::part[position()=last()]">
                          <xsl:apply-templates />
                        </xsl:for-each>
                      <xsl:text disable-output-escaping="yes">" /&gt;</xsl:text>
</xsl:template>

<xsl:template match="target">
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="part">
<xsl:apply-templates/>
</xsl:template>

</xsl:stylesheet>
