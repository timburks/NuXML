/*
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#import "NuXML.h"

#import <libxml/xmlmemory.h>
#import <libxml/xmlstring.h>

@interface NuXMLParser : NSObject
{
    @private
    NSMutableArray *stack;
}

- (id) parseXML:(NSString *)XMLString parseError:(NSError **)parseError;

static void nuXMLStartElement(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void nuXMLEndElement(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void nuXMLCharactersFound(void * ctx, const xmlChar * ch, int len);
static void nuXMLErrorHandler(void * ctx, const char * msg, ...);
static void nuXMLFatalHandler(void * ctx, const char * msg, ...);
@end

static xmlSAXHandler nuSAXHandlerStruct =
{
    NULL,                                         /* internalSubset */
    NULL,                                         /* isStandalone   */
    NULL,                                         /* hasInternalSubset */
    NULL,                                         /* hasExternalSubset */
    NULL,                                         /* resolveEntity */
    NULL,                                         /* getEntity */
    NULL,                                         /* entityDecl */
    NULL,                                         /* notationDecl */
    NULL,                                         /* attributeDecl */
    NULL,                                         /* elementDecl */
    NULL,                                         /* unparsedEntityDecl */
    NULL,                                         /* setDocumentLocator */
    NULL,                                         /* startDocument */
    NULL,                                         /* endDocument */
    NULL,                                         /* startElement*/
    NULL,                                         /* endElement */
    NULL,                                         /* reference */
    nuXMLCharactersFound,                         /* characters */
    NULL,                                         /* ignorableWhitespace */
    NULL,                                         /* processingInstruction */
    NULL,                                         /* comment */
    NULL,                                         /* warning */
    nuXMLErrorHandler,                            /* error */
    nuXMLFatalHandler,                            /* fatalError */
    NULL,                                         /* getParameterEntity */
    NULL,                                         /* cdataBlock */
    NULL,                                         /* externalSubset */
    XML_SAX2_MAGIC,                               //
    NULL,
    nuXMLStartElement,                            /* startElementNs */
    nuXMLEndElement,                              /* endElementNs */
    NULL,                                         /* serror */
};

static xmlSAXHandler *nuSAXHandler = &nuSAXHandlerStruct;

@implementation NuXMLParser

- (id) parseXML:(NSString *)XMLStringObject parseError:(NSError **)parseError
{
    const char *XMLString = [XMLStringObject cStringUsingEncoding:NSUTF8StringEncoding];
    if (!XMLString) {
        return [NSNull null];
    }

    [stack release];
    stack = [[NSMutableArray alloc] init];

    xmlParserCtxtPtr ctxt = xmlCreateDocParserCtxt((xmlChar*)XMLString);

    int parseResult = xmlSAXUserParseMemory(nuSAXHandler, self, XMLString, strlen(XMLString));

    xmlFreeParserCtxt(ctxt);
    xmlCleanupParser();
    xmlMemoryDump();

    if (parseResult != 0 && parseError) {
        *parseError = [NSError
            errorWithDomain:@"XMLParsingErrorDomain"
            code:0
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Parsing failed", @"error", nil]];
        return nil;
    }
    else {
        return [stack lastObject];
    }
}

- (void) dealloc
{
    [stack release];
    [super dealloc];
}

static NSString *getQualifiedName (const xmlChar *prefix, const xmlChar *localName)
{
    if (!localName)
        return nil;
    else if (!prefix)
        return [NSString stringWithFormat:@"%s", localName];
    else
        return [NSString stringWithFormat:@"%s:%s", prefix, localName];
}

static void nuXMLStartElement(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes)
{
    NuXMLParser *currentReader = (NuXMLParser *)ctx;

    id element = getQualifiedName(prefix, localname);
    [currentReader->stack addObject:[NSMutableArray arrayWithObject:element]];

    NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
    int attributeCounter, maxAttributes = nb_attributes * 5;
    for (attributeCounter = 0; attributeCounter < maxAttributes; attributeCounter++) {

        const xmlChar *localName = attributes[attributeCounter];
        attributeCounter++;

        const xmlChar *attributePrefix = attributes[attributeCounter];
        attributeCounter++;

        const char *URI = (const char *)attributes[attributeCounter];
        if (URI) {                                // unused
            NSString *URIString = [[NSString alloc] initWithUTF8String:URI];
        }
        attributeCounter++;

        const char *valueBegin = (const char *)attributes[attributeCounter];
        const char *valueEnd = (const char *)attributes[attributeCounter + 1];
        if (valueBegin && valueEnd) {
            NSString *valueString = [[[NSString alloc]
                initWithBytes:attributes[attributeCounter]
                length:(strlen(valueBegin) - strlen(valueEnd))
                encoding:NSUTF8StringEncoding] autorelease];
            if (valueString) {
                NSString *localNameString = getQualifiedName(attributePrefix, localName);
                [attributeDictionary setObject:valueString forKey:localNameString];
            }
        }
        attributeCounter++;
    }

    if ([attributeDictionary count]) {
        [[currentReader->stack lastObject] addObject:attributeDictionary];
    }
}

static void nuXMLEndElement(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI)
{
    NuXMLParser *currentReader = (NuXMLParser *) ctx;
    if ([currentReader->stack count] > 1) {
        id top = [currentReader->stack lastObject];
        [currentReader->stack removeLastObject];
        [[currentReader->stack lastObject] addObject:top];
    }
}

static void nuXMLCharactersFound(void *ctx, const xmlChar *ch, int len)
{
    NuXMLParser *currentReader = (NuXMLParser *)ctx;
    NSString *string = [[[NSString alloc] initWithBytes:ch length:len encoding:NSUTF8StringEncoding] autorelease];
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([string length] > 0) {
        [[currentReader->stack lastObject] addObject:string];
    }
}

static void nuXMLErrorHandler(void * ctx, const char * msg, ...)
{
    NSLog(@"XML error: %s", msg);
}

static void nuXMLFatalHandler(void * ctx, const char * msg, ...)
{
    NSLog(@"Fatal XML error: %s", msg);
}

@end

@implementation NSString (NuXML)

- (id) xmlValue
{
    id parser = [[[NuXMLParser alloc] init] autorelease];
    id result = [parser parseXML:self parseError:nil];
    return result;
}

@end

@implementation NSArray (NuXML)

- (NSDictionary *) xmlAttributes
{
    id item;
    if (([self count] > 0) && [(item = [self objectAtIndex:1]) isKindOfClass:[NSDictionary class]]) {
        return item;
    }
    else {
        return [NSDictionary dictionary];
    }
}

- (NSArray *) xmlChildren
{
    NSMutableArray *result = [NSMutableArray array];
    int max = [self count];
    for (int i = 1; i < max; i++) {
        id child = [self objectAtIndex:i];
        if ([child isKindOfClass:[NSArray class]]) {
            [result addObject:child];
        }
    }
    return result;
}

- (NSArray *) xmlChildrenWithName:(NSString *) name
{
    NSMutableArray *result = [NSMutableArray array];
    int max = [self count];
    for (int i = 1; i < max; i++) {
        id child = [self objectAtIndex:i];
        if ([child isKindOfClass:[NSArray class]] && [[child objectAtIndex:0] isEqualToString:name]) {
            [result addObject:child];
        }
    }
    return result;
}

- (id) xmlChildWithName:(NSString *) name
{
    int max = [self count];
    for (int i = 1; i < max; i++) {
        id child = [self objectAtIndex:i];
        if ([child isKindOfClass:[NSArray class]] && [[child objectAtIndex:0] isEqualToString:name]) {
            return child;
        }
    }
    return nil;
}

- (id) xmlNodeValue
{
    id element = [self objectAtIndex:1];
    if ([element isKindOfClass:[NSDictionary class]]) {
        return [self objectAtIndex:2];
    }
    else {
        return element;
    }
}

- (id) xmlNodeStringValue {
    id element = [self objectAtIndex:1];
    if ([element isKindOfClass:[NSDictionary class]]) {
        return [[self subarrayWithRange:NSMakeRange(2, [self count]-2)] componentsJoinedByString:@""];
    } else {
        return [[self subarrayWithRange:NSMakeRange(1, [self count]-1)] componentsJoinedByString:@""];
    }
}

- (id) xmlNodeValueOfChildWithName:(NSString *) name
{
    return [[self xmlChildWithName:name] xmlNodeValue];
}

- (id) xmlNodeValueOfChildWithPath:(NSString *) name
{
    id parts = [name componentsSeparatedByString:@"."];
    id cursor = self;
    int i;
    for (i = 0; i < [parts count] - 1; i++) {
        cursor = [cursor xmlChildWithName:[parts objectAtIndex:i]];
    }
    return [cursor xmlNodeValueOfChildWithName:[parts objectAtIndex:i]];
}

@end
