<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
    exclude-result-prefixes="ditaarch"
    version="2.0">
    
    <xsl:template match="/dita/topic">
        <!-- Split subtopics of large topic to new topic files. -->
        <topic>
            <xsl:apply-templates select="@* | node()" mode="split"/>
        </topic>
        
        <!-- Build DITA map with all topics. -->
        <xsl:variable name="mapFileName" 
            select="concat('DITAMAP-', substring-before(tokenize(document-uri(/), '/')[last()], '.'), '.ditamap')"/>
        <xsl:message>DITAMAP file: <xsl:value-of select="normalize-space($mapFileName)"/></xsl:message>
        <xsl:result-document href="{normalize-space($mapFileName)}"
            doctype-public="-//OASIS//DTD DITA Map//EN"
            doctype-system="map.dtd">
            <map title="{normalize-space(title)}">
                <xsl:apply-templates select="*" mode="map"/>
            </map>
        </xsl:result-document>
    </xsl:template>
    
    
    <xsl:template match="@* | node()" mode="split">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="split"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@platform" mode="split">
        <xsl:attribute name="platform" select="string-join(tokenize(., ';'), ' ')"/>
    </xsl:template>
    
    <xsl:template match="indexterm" mode="split">
        <p outputclass="db.indexterm">
            <xsl:copy-of select="."/>
        </p>
    </xsl:template>
    
  <!-- EXM-16853 -->
    <xsl:template match="link" mode="split">
        <xsl:apply-templates select="*"/>
    </xsl:template>
  
  <xsl:template match="@ditaarch:DITAArchVersion | 
                                     @domains | 
                                     @class | 
                                     @outputclass"
                                     mode="split"/>

    <xsl:template match="xref[not(@scope)]" mode="split">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="split"/>
            <xsl:if test="starts-with(@href, 'http')">
                <xsl:attribute name="scope" select="'external'"/>
                <xsl:attribute name="format" select="'html'"/>
            </xsl:if>
            <xsl:apply-templates select="* | text()" mode="split"/>
        </xsl:copy>
    </xsl:template>
    

    <xsl:template match="topic" mode="split">
        <xsl:variable name="splitFileName">
            <xsl:choose>
                <xsl:when test="@id">
                    <xsl:value-of select="@id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="translate(title, ' ', '_')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:message>TOPIC file: <xsl:value-of select="normalize-space($splitFileName)"/></xsl:message>
        
        <xsl:variable name="splitFileNameWithExt" select="concat($splitFileName, '.xml')"/>
        <xsl:result-document href="{$splitFileNameWithExt}" 
            doctype-public="-//OASIS//DTD DITA Topic//EN" 
            doctype-system="topic.dtd">
                <topic xsl:exclude-result-prefixes="ditaarch">
                    <xsl:apply-templates select="@* | node()" mode="split"/>
                </topic>
        </xsl:result-document>
    </xsl:template>
    
    
    <xsl:template match="*" mode="map">
        <xsl:apply-templates select="*" mode="map"/>
    </xsl:template>
    
    
    <xsl:template match="topic" mode="map">
        <xsl:variable name="topicTitle">
            <xsl:choose>
                <xsl:when test="title/ph"><xsl:value-of select="title/ph[1]"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="title"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <topicref href="{@id}.xml" navtitle="{normalize-space($topicTitle)}">
            <xsl:if test="@platform">
                <xsl:attribute name="platform" select="string-join(tokenize(@platform, ';'), ' ')"/>
            </xsl:if>
            <xsl:apply-templates select="* | text()" mode="map"/>
        </topicref>
    </xsl:template>
</xsl:stylesheet>
