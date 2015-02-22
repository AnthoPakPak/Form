@import UIKit;
@import XCTest;

#import "FORMFieldValidation.h"
#import "FORMGroup.h"
#import "FORMField.h"
#import "FORMCollectionViewDataSource.h"
#import "FORMSection.h"
#import "FORMData.h"
#import "FORMTarget.h"
#import "HYPImageFormFieldCell.h"
#import "HYPSampleCollectionViewController.h"

#import "NSJSONSerialization+ANDYJSONFile.h"

@interface HYPSampleCollectionViewController ()

@property (nonatomic, strong) FORMCollectionViewDataSource *dataSource;

@end

@interface HYPFormsCollectionViewDataSourceTests : XCTestCase

@end

@implementation HYPFormsCollectionViewDataSourceTests

- (HYPSampleCollectionViewController *)controller
{
    NSArray *JSON = [NSJSONSerialization JSONObjectWithContentsOfFile:@"forms.json"];

    HYPSampleCollectionViewController *controller = [[HYPSampleCollectionViewController alloc] initWithJSON:JSON andInitialValues:@{}];

    return controller;
}

- (void)testIndexInForms
{
    HYPSampleCollectionViewController *controller = [self controller];

    [controller.dataSource processTarget:[FORMTarget hideFieldTargetWithID:@"display_name"]];
    [controller.dataSource processTarget:[FORMTarget showFieldTargetWithID:@"display_name"]];
    FORMField *field = [controller.dataSource.formsManager fieldWithID:@"display_name" includingHiddenFields:YES];
    NSUInteger index = [field indexInSectionUsingForms:controller.dataSource.formsManager.forms];
    XCTAssertEqual(index, 2);

    [controller.dataSource processTarget:[FORMTarget hideFieldTargetWithID:@"username"]];
    [controller.dataSource processTarget:[FORMTarget showFieldTargetWithID:@"username"]];
    field = [controller.dataSource.formsManager fieldWithID:@"username" includingHiddenFields:YES];
    index = [field indexInSectionUsingForms:controller.dataSource.formsManager.forms];
    XCTAssertEqual(index, 2);

    [controller.dataSource processTargets:[FORMTarget hideFieldTargetsWithIDs:@[@"first_name",
                                                                             @"address",
                                                                             @"username"]]];
    [controller.dataSource processTarget:[FORMTarget showFieldTargetWithID:@"username"]];
    field = [controller.dataSource.formsManager fieldWithID:@"username" includingHiddenFields:YES];
    index = [field indexInSectionUsingForms:controller.dataSource.formsManager.forms];
    XCTAssertEqual(index, 1);
    [controller.dataSource processTargets:[FORMTarget showFieldTargetsWithIDs:@[@"first_name",
                                                                             @"address"]]];

    [controller.dataSource processTargets:[FORMTarget hideFieldTargetsWithIDs:@[@"last_name",
                                                                             @"address"]]];
    [controller.dataSource processTarget:[FORMTarget showFieldTargetWithID:@"address"]];
    field = [controller.dataSource.formsManager fieldWithID:@"address" includingHiddenFields:YES];
    index = [field indexInSectionUsingForms:controller.dataSource.formsManager.forms];
    XCTAssertEqual(index, 0);
    [controller.dataSource processTarget:[FORMTarget showFieldTargetWithID:@"last_name"]];
}

- (void)testEnableAndDisableTargets
{
    HYPSampleCollectionViewController *controller = [self controller];
    [controller.dataSource enable];

    FORMField *targetField = [controller.dataSource.formsManager fieldWithID:@"base_salary" includingHiddenFields:YES];
    XCTAssertFalse(targetField.isDisabled);

    FORMTarget *disableTarget = [FORMTarget disableFieldTargetWithID:@"base_salary"];
    [controller.dataSource processTarget:disableTarget];
    XCTAssertTrue(targetField.isDisabled);

    FORMTarget *enableTarget = [FORMTarget enableFieldTargetWithID:@"base_salary"];
    [controller.dataSource processTargets:@[enableTarget]];
    XCTAssertFalse(targetField.isDisabled);

    [controller.dataSource disable];
    XCTAssertTrue(targetField.isDisabled);

    [controller.dataSource enable];
    XCTAssertFalse(targetField.isDisabled);
}

- (void)testInitiallyDisabled
{
    HYPSampleCollectionViewController *controller = [self controller];

    FORMField *totalField = [controller.dataSource.formsManager fieldWithID:@"total" includingHiddenFields:YES];
    XCTAssertTrue(totalField.disabled);
}

- (void)testUpdatingTargetValue
{
    HYPSampleCollectionViewController *controller = [self controller];

    FORMField *targetField = [controller.dataSource.formsManager fieldWithID:@"display_name" includingHiddenFields:YES];
    XCTAssertNil(targetField.fieldValue);

    FORMTarget *updateTarget = [FORMTarget updateFieldTargetWithID:@"display_name"];
    updateTarget.targetValue = @"John Hyperseed";

    [controller.dataSource processTarget:updateTarget];
    XCTAssertEqualObjects(targetField.fieldValue, @"John Hyperseed");
}

- (void)testDefaultValue
{
    HYPSampleCollectionViewController *controller = [self controller];

    FORMField *usernameField = [controller.dataSource.formsManager fieldWithID:@"username" includingHiddenFields:YES];
    XCTAssertNotNil(usernameField.fieldValue);
}

- (void)testCondition
{
    HYPSampleCollectionViewController *controller = [self controller];

    FORMField *displayNameField = [controller.dataSource.formsManager fieldWithID:@"display_name" includingHiddenFields:YES];
    FORMField *usernameField = [controller.dataSource.formsManager fieldWithID:@"username" includingHiddenFields:YES];
    FORMFieldValue *fieldValue = usernameField.fieldValue;
    XCTAssertEqualObjects(fieldValue.valueID, @0);

    FORMTarget *updateTarget = [FORMTarget updateFieldTargetWithID:@"display_name"];
    updateTarget.targetValue = @"Mr.Melk";

    updateTarget.condition = @"$username == 2";
    [controller.dataSource processTarget:updateTarget];
    XCTAssertNil(displayNameField.fieldValue);

    updateTarget.condition = @"$username == 0";
    [controller.dataSource processTarget:updateTarget];
    XCTAssertEqualObjects(displayNameField.fieldValue, @"Mr.Melk");
}

- (void)testReloadWithDictionary
{
    HYPSampleCollectionViewController *controller = [self controller];

    [controller.dataSource reloadWithDictionary:@{@"first_name" : @"Elvis",
                                            @"last_name" : @"Nunez"}];

    FORMField *field = [controller.dataSource.formsManager fieldWithID:@"display_name" includingHiddenFields:YES];
    XCTAssertEqualObjects(field.fieldValue, @"Elvis Nunez");
}

- (void)testClearTarget
{
    HYPSampleCollectionViewController *controller = [self controller];

    FORMField *firstNameField = [controller.dataSource.formsManager fieldWithID:@"first_name" includingHiddenFields:YES];
    XCTAssertNotNil(firstNameField);

    firstNameField.fieldValue = @"John";
    XCTAssertNotNil(firstNameField.fieldValue);

    FORMTarget *clearTarget = [FORMTarget clearFieldTargetWithID:@"first_name"];
    [controller.dataSource processTarget:clearTarget];
    XCTAssertNil(firstNameField.fieldValue);
}

- (void)testFormFieldsAreValid
{
    NSArray *JSON = [NSJSONSerialization JSONObjectWithContentsOfFile:@"field-validations.json"
                                                             inBundle:[NSBundle bundleForClass:[self class]]];

    HYPSampleCollectionViewController *controller = [[HYPSampleCollectionViewController alloc] initWithJSON:JSON andInitialValues:@{}];
    XCTAssertFalse([controller.dataSource formFieldsAreValid]);

    [controller.dataSource reloadWithDictionary:@{@"first_name" : @"Supermancito"}];

    XCTAssertTrue([controller.dataSource formFieldsAreValid]);
}

@end
