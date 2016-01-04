<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:ex="http://exslt.org/dates-and-times"
  xmlns:sv="http://www.jcp.org/jcr/sv/1.0"
  xmlns:image="http://www.modeshape.org/images/1.0"
  xmlns:space="preserve"

  extension-element-prefixes="exsl ex">
  <xsl:output method="xml" indent="yes"/>
  <xsl:preserve-space elements="sv:node sv:property sv:value"/>
    <xsl:template match="/root/record">
      <xsl:copy>
        <exsl:document method="xml" href="imports/{identifier}.xml">
          <sv:node xmlns:premis="http://www.loc.gov/premis/rdf/v1#"
            xmlns:image="http://www.modeshape.org/images/1.0"
            xmlns:sv="http://www.jcp.org/jcr/sv/1.0"
            xmlns:test="info:fedora/test/" xmlns:nt="http://www.jcp.org/jcr/nt/1.0"
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xmlns:ns003="http://library.upenn.edu/ns/"
            xmlns:ns002="http://purl.org/dc/terms/"
            xmlns:ns001="info:fedora/fedora-system:def/model#"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:mode="http://www.modeshape.org/1.0"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xmlns:fedora="http://fedora.info/definitions/v4/repository#"
            xmlns:jcr="http://www.jcp.org/jcr/1.0"
            xmlns:ldp="http://www.w3.org/ns/ldp#"
            xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:fedoraconfig="http://fedora.info/definitions/v4/config#"
            xmlns:mix="http://www.jcp.org/jcr/mix/1.0"
            xmlns:foaf="http://xmlns.com/foaf/0.1/"
            xmlns:dc="http://purl.org/dc/elements/1.1/">
            <xsl:attribute name="sv:name"><xsl:value-of select="identifier" /></xsl:attribute>
          <sv:property sv:name="jcr:primaryType" sv:type="Name">
            <sv:value>nt:folder</sv:value>
          </sv:property>
          <sv:property sv:name="jcr:mixinTypes" sv:type="Name" sv:multiple="true">
            <sv:value>fedora:Container</sv:value>
            <sv:value>fedora:Resource</sv:value>
          </sv:property>
          <sv:property sv:name="jcr:lastModifiedBy" sv:type="String">
            <sv:value>bypassAdmin</sv:value>
          </sv:property>
          <sv:property sv:name="ns001:hasModel" sv:type="String" sv:multiple="true">
            <sv:value><xsl:value-of select="item_type" /></sv:value>
          </sv:property>
          <sv:property sv:name="jcr:createdBy" sv:type="String">
            <sv:value>bypassAdmin</sv:value>
          </sv:property>
          <sv:property sv:name="ns002:abstract" sv:type="String" sv:multiple="true">
            <sv:value><xsl:value-of select="abstract" /></sv:value>
          </sv:property>
          <sv:property sv:name="ns002:coverage" sv:type="String" sv:multiple="true">
            <sv:value><xsl:value-of select="coverage" /></sv:value>
          </sv:property>
          <sv:property sv:name="ns002:identifier" sv:type="String" sv:multiple="true">
            <sv:value><xsl:apply-templates select="identifier"/></sv:value>
          </sv:property>
          <sv:property sv:name="ns002:language" sv:type="String" sv:multiple="true">
            <sv:value><xsl:value-of select="language" /></sv:value>
          </sv:property>
          <sv:property sv:name="ns002:description" sv:type="String" sv:multiple="true">
            <xsl:apply-templates select="description" />
          </sv:property>
          <sv:property sv:name="ns003:file_location" sv:type="String" sv:multiple="true">
            <xsl:apply-templates select="file_location" />
          </sv:property>
          <sv:property sv:name="ns002:item_type" sv:type="String" sv:multiple="true">
            <sv:value><xsl:value-of select="item_type" /></sv:value>
          </sv:property>
          <sv:property sv:name="ns002:title" sv:type="String" sv:multiple="true">
            <sv:value><xsl:value-of select="title" /></sv:value>
          </sv:property>
          <sv:property sv:name="ns002:date" sv:type="String" sv:multiple="true">
            <sv:value><xsl:value-of select="date" /></sv:value>
          </sv:property>

        </sv:node>
        </exsl:document>
      </xsl:copy>
    </xsl:template>
    <xsl:template match="description">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>
    <xsl:template match="file_location">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>
</xsl:stylesheet>