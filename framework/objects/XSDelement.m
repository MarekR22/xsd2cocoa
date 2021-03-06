/*
 XSDelement.h
 The implementation of properties and methods for the XSDelement object.
 Generated by SudzC.com
 */
#import "XSDelement.h"
#import "XSDcomplexType.h"
#import "XSDschema.h"
#import "XMLUtils.h"
#import "XSSimpleType.h"
#import "XSDenumeration.h"
#import "XSSimpleType.h"

@interface XSSimpleType (privateAccessors)
@property (strong, nonatomic) NSString *name;
@end
@interface XSDcomplexType (privateAccessors)
@property (strong, nonatomic) NSString *name;
@end

@interface XSDelement ()
@property (strong, nonatomic) id<XSType> localType;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* type;
@property (strong, nonatomic) NSString* substitutionGroup;
@property (strong, nonatomic) NSString* defaultValue;
@property (strong, nonatomic) NSString* fixed;
@property (strong, nonatomic) NSString* nillable;
@property (strong, nonatomic) NSString* abstractValue;
@property (strong, nonatomic) NSString* final;
@property (strong, nonatomic) NSString* block;
@property (strong, nonatomic) NSString* form;
@property (strong, nonatomic) NSNumber* minOccurs;
@property (strong, nonatomic) NSNumber* maxOccurs;
@end

@implementation XSDelement

- (id) initWithNode:(NSXMLElement*)node schema: (XSDschema*)schema {
    self = [super initWithNode:node schema:schema];
    if(self) {
        self.type = [XMLUtils node: node stringAttribute: @"type"];
        self.name = [XMLUtils node: node stringAttribute: @"name"];
        self.substitutionGroup = [XMLUtils node: node stringAttribute: @"substitutionGroup"];
        self.defaultValue = [XMLUtils node: node stringAttribute:  @"default"];
        self.fixed = [XMLUtils node: node stringAttribute: @"fixed"];
        self.nillable = [XMLUtils node: node stringAttribute: @"nillable"];
        self.abstractValue = [XMLUtils node: node stringAttribute: @"abstract"];
        self.final = [XMLUtils node: node stringAttribute: @"final"];
        self.block = [XMLUtils node: node stringAttribute: @"block"];
        self.form = [XMLUtils node: node stringAttribute: @"form"];

        NSNumberFormatter* numFormatter = [[NSNumberFormatter alloc] init];
        numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        NSString* minOccursValue = [XMLUtils node: node stringAttribute: @"minOccurs"];
        if(minOccursValue == nil) {
            self.minOccurs = [NSNumber numberWithInt: 1];
        } else if([minOccursValue isEqual: @"unbounded"]) {
            self.minOccurs = [NSNumber numberWithInt: -1];
        } else {
            self.minOccurs = [numFormatter numberFromString: minOccursValue];
        }
        
        NSString* maxOccursValue = [XMLUtils node: node stringAttribute: @"maxOccurs"];
        if(maxOccursValue == nil) {
            self.maxOccurs = [NSNumber numberWithInt: 1];
        } else if([maxOccursValue isEqual: @"unbounded"]) {
            self.maxOccurs = [NSNumber numberWithInt: -1];
        } else {
            self.maxOccurs = [numFormatter numberFromString: maxOccursValue];
        }
        
        /* If we do not have a type defined yet */
        if(self.type == nil) {
            /* Check if we have a complex type defined for the given element */
            NSXMLElement* complexTypeNode = [XMLUtils node:node childWithName:@"complexType"];
            if(complexTypeNode != nil) {
                self.localType = [[XSDcomplexType alloc] initWithNode:complexTypeNode schema:schema];
                ((XSDcomplexType*)self.localType).name = [self.name stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self.name substringToIndex:1] uppercaseString]];
                [schema addType: self.localType];
            }
            else {
                NSXMLElement* simpleTypeNode = [XMLUtils node:node childWithName:@"simpleType"];
                if(simpleTypeNode != nil) {
                    self.localType = [[XSSimpleType alloc] initWithNode:simpleTypeNode schema:schema];
                    ((XSSimpleType*)self.localType).name = [self.name stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self.name substringToIndex:1] uppercaseString]];
                    [schema addType: self.localType];
                }
            }
        }

        NSAssert(self.name, @"no name");
        
        //specify string as default value
        if(!self.type && !self.localType) {
            NSLog(@"assign default tye xs:string to element %@", self.name);
            self.type = @"xs:string";
        }
    }
    return self;
}

- (BOOL) hasComplexType {
//    return (self.type != nil && [[self.schema typeForName:self.type] isKindOfClass:[XSDcomplexType class]]);
    return [self.schemaType isKindOfClass:[XSDcomplexType class]];
}

- (NSString*) codeType {
    NSString* rtn;
    if([self isSingleValue]) {
        if(self.type != nil) {
            id<XSType> type =[self.schema typeForName:self.type];
            rtn = [type targetClassName];
        } else {
            rtn = [self.localType targetClassName];
        }
    } else {
        if(self.type != nil) {
            rtn = [[self.schema typeForName:self.type] arrayType];
        } else {
            rtn = self.localType.arrayType;
        }
    }
    
    return rtn;
}

- (id<XSType>) schemaType {
    if(self.type != nil) {
        return [self.schema typeForName: self.type];
    } else {
        return self.localType;
    }
}

- (NSString*) variableName {
    return [XSDschema variableNameFromName:self.name multiple:!self.isSingleValue];
}

/* 
 * Name:        hasEnumeration
 * Parameters:  None
 * Returns:     BOOL value that will equate to 
 *              0 - NO - False.
 *              1 - YES - True
 * Description: Will check the current element to see if the element type is associated 
 *              with an enumeration values.
 */
- (BOOL) hasEnumeration{
    BOOL isEnumeration = NO;
    
    /* Grab the type and check if it is of a simple type element */
    XSSimpleType* type = (XSSimpleType*)self.schemaType;
    if([type isKindOfClass:[XSSimpleType class]]) {
        /* ask the type */
        isEnumeration = [type hasEnumeration];
    }
    
    /* Return BOOL if we have enumerations */
    return isEnumeration;
}

- (NSString*) nameWithCapital {
    return [[self variableName] stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self.name substringToIndex:1] uppercaseString]];
}

- (NSString*) readCodeForContent {
    NSString *rtn;
    
    /* Fetch the type and from those objects, call their appropriate method */
    if(self.localType != nil) {
        rtn = [self.localType readCodeForElement:self];
    }
    else if(self.hasEnumeration){
        XSSimpleType* simpleTypeTemp = self.schemaType;
        rtn = [simpleTypeTemp readCodeForElement:self];
    } else {
        /* Fetch the type of the current element from the schema dictionaries and read the template code and generate final code */
        rtn = [[self.schema typeForName:self.type] readCodeForElement:self];
    }
    
    return rtn;
}

- (BOOL) isSingleValue {
    return [self.maxOccurs intValue] >= 0 && [self.maxOccurs intValue] <= 1;
}

@end
