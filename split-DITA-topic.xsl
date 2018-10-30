<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
    exclude-result-prefixes="#all"
    xmlns:oxy="http://www.oxygenxml.com/ns"
    version="2.0">
    
    <xsl:output indent="yes"/>
    
    <xsl:template match="/dita/topic">
        <!-- Split subtopics of large topic to new topic files. -->
        <topic>
            <xsl:apply-templates select="@* | node()" mode="split"/>
        </topic>
        
        <!-- Build DITA map with all topics. -->
        <xsl:variable name="mapFileName" 
            select="concat('DITAMAP-', substring-before(tokenize(document-uri(/), '/')[last()], '.'), '.ditamap')"/>
        <xsl:message>DITAMAP file: <xsl:value-of select="normalize-space($mapFileName)"/></xsl:message>
        <xsl:result-document href="{normalize-space($mapFileName)}" indent="yes"
            doctype-public="-//OASIS//DTD DITA BookMap//EN"
            doctype-system="bookmap.dtd">
            <bookmap>
                <xsl:attribute name="id" select="/dita/topic[1]/@id"/>
                <xsl:attribute name="xml:lang" select="'en-US'"/>
                <booktitle><mainbooktitle><xsl:value-of select="title"/></mainbooktitle></booktitle>
                <bookmeta>
                    <xsl:variable name="info" select="/dita/*:info"/>
                    <author><xsl:value-of select="$info/*:authorgroup/*:author" separator=" "/></author>
                    <publisherinformation>
                        <published>
                            <completed>
                                <month><xsl:value-of select="substring-before($info/*:pubdate, ' ')"/></month>
                                <year><xsl:value-of select="substring-after($info/*:pubdate, ' ')"/></year>
                            </completed>
                        </published>
                    </publisherinformation>
                    <bookid>
                        <bookpartno><xsl:value-of select="$info/*:biblioid[@class='pubsnumber']"/></bookpartno>
                         <volume/>
                    </bookid>
                    <bookrights>
                        <copyrfirst>
                            <year><xsl:value-of select="substring-before($info/*:copyright/*:year, ', ')"/></year>
                        </copyrfirst>
                        <copyrlast>
                            <year><xsl:value-of select="substring-after($info/*:copyright/*:year, ', ')"/></year>
                        </copyrlast>
                        <bookowner>
                            <organization><xsl:value-of select="$info/*:copyright/*:holder"/></organization>
                        </bookowner>
                    </bookrights>
                </bookmeta>
                <xsl:apply-templates select="*" mode="map"/>
            </bookmap>			
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
    
  <!-- EXM-16853 -->
    <xsl:template match="link" mode="split">
        <xsl:apply-templates select="*"/>
    </xsl:template>
  
  <xsl:template match="@ditaarch:DITAArchVersion | 
                                     @domains | 
                                     @class | 
                                     @outputclass"
                                     mode="split map"/>

    <xsl:template match="xref | link" mode="split">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="split"/>
            <!-- Now fix up the @href -->
            <xsl:if test="starts-with(@href, '#')">
                <xsl:variable name="hrefValue" select="@href"/>
                <xsl:variable name="targetElement" select="(//*[@id = substring-after($hrefValue, '#')])[1]"/>
                <xsl:if test="$targetElement">
                    <xsl:variable name="closestTargetTopic" select="$targetElement/(ancestor-or-self::*[local-name() = ('topic', 'task', 'concept', 'reference')])[last()]"/>
                    <xsl:if test="$closestTargetTopic">
                        <xsl:choose>
                            <xsl:when test="$closestTargetTopic = $targetElement">
                                <xsl:attribute name="href" select="oxy:getTopicFileName($closestTargetTopic)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="href" select="concat(oxy:getTopicFileName($closestTargetTopic), '#', normalize-space($closestTargetTopic/@id)), '/', normalize-space($targetElement/@id)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                </xsl:if>
            </xsl:if>
            <xsl:if test="starts-with(@href, 'http')">
                <xsl:attribute name="scope" select="'external'"/>
                <xsl:attribute name="format" select="'html'"/>
            </xsl:if>
            <xsl:apply-templates select="* | text()" mode="split"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:function name="oxy:getTopicFileName">
        <xsl:param name="topicElement"/>
        <xsl:variable name="fileName">
            <xsl:choose>
                <xsl:when test="$topicElement/@id">
                    <xsl:value-of select="$topicElement/@id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="translate($topicElement/title, ' ', '_')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="fileNameWithExt" select="normalize-space(concat($fileName, '.xml'))"/>
        <xsl:value-of select="$fileNameWithExt"/>
    </xsl:function>
    

    <xsl:template match="topic|task|concept|reference" mode="split">
        
        <xsl:variable name="fileName" select="oxy:getTopicFileName(.)"/>
        <xsl:message>TOPIC file: <xsl:value-of select="normalize-space($fileName)"/></xsl:message>
        
        
        <xsl:variable name="topicName">
            <xsl:choose>
                <xsl:when test="local-name() = 'task'">Task</xsl:when>
                <xsl:when test="local-name() = 'Concept'">Concept</xsl:when>
                <xsl:when test="local-name() = 'Reference'">Reference</xsl:when>
                <xsl:otherwise>Topic</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:result-document href="{$fileName}" 
            doctype-public="-//OASIS//DTD DITA {$topicName}//EN" 
            doctype-system="{lower-case($topicName)}.dtd" indent="yes" exclude-result-prefixes="#all">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="split"/>
            </xsl:copy>
        </xsl:result-document>
    </xsl:template>
    
    
    <xsl:template match="node()" mode="map">
        <xsl:apply-templates select="node()" mode="map"/>
    </xsl:template>
	
	
    
    
    <xsl:template match="topic|task|concept|reference" mode="map">
            <xsl:choose>
                <xsl:when test="starts-with(@id, 'PREFACE')">
                    <frontmatter>
                        <notices />
                        <preface href="{@id}.xml">
                            <xsl:apply-templates select="* | text()" mode="map"/>			    
                        </preface>
                    </frontmatter>			             
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="topicrefElementName">
                        <xsl:choose>
                            <xsl:when test="count(ancestor::*[local-name() = ('topic', 'task', 'concept', 'reference')]) = 1">
                                <!-- If this is on the first level, use a <chapter> element to refer to it -->
                                <xsl:value-of select="'chapter'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'topicref'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:element name="{$topicrefElementName}">
                        <xsl:attribute name="href" select="concat(@id, '.xml')"/>
                        <xsl:if test="@platform">
                            <xsl:attribute name="platform" select="string-join(tokenize(@platform, ';'), ' ')"/>
                        </xsl:if>
                        <xsl:apply-templates select="* | text()" mode="map"/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
		</xsl:template>
    
       <!-- 
       In all the individual files, in the <image> element change attribute 
       placement="break"
        to: scalefit="yes". Without this the image not be displayed 
        properly

       -->
		
		<xsl:template match="@placement[.='break']" mode="split">
		    <xsl:copy/>
           <xsl:attribute name="scalefit" select ="'yes'"/>
        </xsl:template>
		
   <!-- 
   In all the individual files, add rowheader="firstcol" as an attribute to all
   <table> elements without 
   which tables are not rendered properly. 
   -->	
    <xsl:template match="table"  mode="split">
		<xsl:copy>
		    <!-- Copy all existing attributes -->
		    <xsl:apply-templates select="@*"/>
            <xsl:attribute name="rowheader" select="'firstcol'"/>
		    <xsl:apply-templates select="node()"/>
         </xsl:copy>
    </xsl:template>
		
</xsl:stylesheet>
