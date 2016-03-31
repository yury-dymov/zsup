//
//  ProjectAPI.m
//  zsup
//
//  Created by Dymov, Yuri on 11.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import "ProjectAPI.h"
#import "SSZipArchive.h"
#import "UpdateGeneratedCode.h"
#import "MigrateToSUPVersion.h"

@implementation ProjectAPI
@synthesize SUPVersion;

static NSMutableDictionary *m_projects;

+ (ProjectAPI*)getInstanceForProjectPath:(NSString *)aProjectPath {
    if (aProjectPath.length) {
        ProjectAPI *ret = [[ProjectAPI alloc] initWithProjectPath:aProjectPath];
        [m_projects setValue:ret forKey:aProjectPath];
        [ret release];
        return ret;
    }
    return nil;
}

- (id)_processProjectFileWithContent:(NSString*)str {
    NSRange bracketLoc = [str rangeOfString:@"{"];
    if (bracketLoc.location != NSNotFound) {
        NSMutableDictionary *ret = [NSMutableDictionary new];
        NSRange var;
        var.location = 0;
        NSRange value;
        NSInteger inside = 0;
        BOOL closed = YES;
        for (NSInteger i = bracketLoc.location + 1; i < str.length; ++i) {
            if (!var.location)
                var.location = i;
            if ([str characterAtIndex:i] == '"') {
                closed = !closed;
            }
            if (closed) {
                if ([str characterAtIndex:i] == '=' && !inside) {
                    var.length = i - var.location;
                    value.location = i + 1;
                } else if ([str characterAtIndex:i] == ';' && !inside) {
                    value.length = i - value.location;
                    [ret setValue:[self _processProjectFileWithContent:[str substringWithRange:value]] forKey:[[str substringWithRange:var] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                    var.location = 0;
                } else if ([str characterAtIndex:i] == '{')
                    ++inside;
                else if ([str characterAtIndex:i] == '}')
                    --inside;
            }
        }
        return [ret autorelease];
    }
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)_loadProjectFile {    
    NSString *projectFile = [projectPath stringByAppendingPathComponent:@"project.pbxproj"];
    NSString *file = [NSString stringWithContentsOfFile:projectFile encoding:NSUTF8StringEncoding error:nil];
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"/\\*([^*]|[\\r\\n]|(\\*+([^*/]|[\\r\\n])))*\\*+/"
                                  options:0
                                  error:nil];
    file = [regex stringByReplacingMatchesInString:file options:0 range:NSMakeRange(0, file.length) withTemplate:@""];
    
    NSRegularExpression *versionRegex = [NSRegularExpression regularExpressionWithPattern:@"SUP[0-9]+.framework" options:0 error:nil];
    NSArray *versionMatches = [versionRegex matchesInString:file options:0 range:NSMakeRange(0, file.length)];
    [SUPVersion release];
    if (versionMatches.count) {
        SUPVersion = [[[file substringWithRange:[[versionMatches objectAtIndex:0] range]] stringByReplacingOccurrencesOfString:@".framework" withString:@""] retain];
    } else {
        SUPVersion = nil;
    }
    [projectDict release];    
    projectDict = [self _processProjectFileWithContent:file];    
}

- (NSString*)_makeOutputFromDict:(NSDictionary*)dict {
    NSString *ret = @"{\n";
    for (NSString *key in dict.allKeys) {
        id value = [dict valueForKey:key];
        if ([[dict valueForKey:key] isKindOfClass:[NSDictionary class]]) {
            value = [self _makeOutputFromDict:value];
        }
        ret = [ret stringByAppendingString:[NSString stringWithFormat:@"\t%@ = %@;\n", key, value]];
    }
    return [ret stringByAppendingString:@"}"];
}

- (void)_updateProjectFile {
    NSString *projectFile = [projectPath stringByAppendingPathComponent:@"project.pbxproj"];
    NSString *enc = @"//!$*UTF8*$!\n";
    NSString *output = [enc stringByAppendingString:[self _makeOutputFromDict:projectDict]];
    [output writeToFile:projectFile atomically:YES encoding:NSUTF8StringEncoding error:nil];    
}

- (id)initWithProjectPath:(NSString*)aProjectPath {
    self = [super init];
    if (self) {
        projectPath = [aProjectPath retain];
        if (!m_projects)
            m_projects = [NSMutableDictionary new];
        [self _loadProjectFile];
    }
    return self;
}

- (void)updateGeneratedCodeFromArchive:(NSString *)archivePath {
    NSString *destination = [projectPath stringByAppendingPathComponent:@".ztemp"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:destination]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:destination withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [SSZipArchive unzipFileAtPath:archivePath toDestination:destination];
    NSString *projectFilesPath = [[projectPath stringByReplacingOccurrencesOfString:@".xcodeproj" withString:@""] stringByAppendingPathComponent:@"Generated Code"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:projectFilesPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:projectFilesPath error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:projectFilesPath withIntermediateDirectories:YES attributes:nil error:nil];
    NSError *err;
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:destination error:nil]) {
        [[NSFileManager defaultManager] moveItemAtPath:[destination stringByAppendingPathComponent:file] toPath:[projectFilesPath stringByAppendingPathComponent:file] error:&err];
    }
    [[NSFileManager defaultManager] removeItemAtPath:destination error:nil];
    
    UpdateGeneratedCode *ugc = [[UpdateGeneratedCode alloc] initWithProjectDict:projectDict andProjectPath:projectFilesPath];
    [ugc process];
    [ugc release];
    
    [self _updateProjectFile];
}

- (void)migrateToSUPVersion:(NSString *)newSUPVersion {
    if (![newSUPVersion isEqualToString:SUPVersion]) {
        [MigrateToSUPVersion migrateFromVersion:SUPVersion toVersion:newSUPVersion withObjectDict:[projectDict valueForKey:@"objects"] andProjectPath:projectPath];
        [SUPVersion release];
        SUPVersion = [newSUPVersion retain];
        [self _updateProjectFile];        
    }
}


- (NSString*)buildReversePathForDict:(NSString*)key intermediateResult:(NSString*)res{
    NSDictionary *objects = [projectDict valueForKey:@"objects"];
    for (NSString *newKey in objects.allKeys) {
        NSDictionary *objectElem = [objects valueForKey:newKey];
        if ([[objectElem valueForKey:@"isa"] isEqualToString:@"PBXGroup"] && [[objectElem valueForKey:@"children"] rangeOfString:key].location != NSNotFound) {
            NSString *path = [[objectElem valueForKey:@"path"] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            if (path.length) {
                if (!res) {
                    return [self buildReversePathForDict:newKey intermediateResult:path];
                } else {
                    return [self buildReversePathForDict:newKey intermediateResult:[path stringByAppendingPathComponent:res]];
                }
            }
            return res;
        }
    }
    return nil;
}

- (void)fixImports {
    NSArray *supHeaders = [NSArray arrayWithObjects: @"NSMutableArray+QueueSupport.h", @"PerformanceAgent.h", @"PerformanceCounter.h", @"sup_json.h", @"SUPAbstractDB.h", @"SUPAbstractDBRBS.h", @"SUPAbstractOperationException.h", @"SUPAbstractPersonalization.h", @"SUPAbstractPersonalizationParameters.h", @"SUPAnnotations.h", @"SUPAssertionFailedException.h", @"SUPAttributeMap.h", @"SUPAttributeMetaData.h", @"SUPAttributeMetaData_DC.h", @"SUPAttributeMetaDataProtocol.h", @"SUPAttributeMetaDataRBS.h", @"SUPAuthExceptionUtil.h", @"SUPBase64Encoding.h", @"SUPBase64EncodingException.h", @"SUPBasicTypes.h", @"SUPBinaryUtil.h", @"SUPBindUtil.h", @"SUPBooleanUtil.h", @"SUPBTXUploadHandler.h", @"SUPCircularBuffer.h", @"SUPClassDelegate.h", @"SUPClassMap.h", @"SUPClassMetaData.h", @"SUPClassMetaDataRBS.h", @"SUPClassWithMetaData.h", @"SUPClientPersonalization.h", @"SUPClientPersonalizationDelegate.h", @"SUPClientRTStringLiterals.h", @"SUPConcurrentReadWriteLock.h", @"SUPConsoleUtil.h", @"SUPDatabaseDelegate.h", @"SUPDatabaseManagerFactory.h", @"SUPDatabaseMetaData.h", @"SUPDatabaseMetaDataProtocol.h", @"SUPDatabaseMetaDataRBS.h", @"SUPDataEncryption.h", @"SUPDateTimeUtil.h", @"SUPDateUtil.h", @"SUPDeliverMessage.h", @"SUPDynamicAttributes.h", @"SUPE2ETraceException.h", @"SUPE2ETraceMessage.h", @"SUPEntityDelegate.h", @"SUPEntityMap.h", @"SUPEntityMetaData.h", @"SUPEntityMetaDataProtocol.h", @"SUPEntityMetaDataRBS.h", @"SUPIndexMetaData.h", @"SupInterface.h", @"SUPJsonArray.h", @"SUPJsonBigBinary.h", @"SUPJsonBigString.h", @"SUPJsonBoolean.h", @"SUPJsonCharToken.h", @"SUPJsonException.h", @"SUPJsonInputStream.h", @"SUPJsonMessage.h", @"SUPJsonNumber.h", @"SUPJsonObject.h", @"SUPJsonReader.h", @"SUPJsonRpcException.h", @"SUPJsonSmsException.h", @"SUPJsonStreamParser.h", @"SUPJsonStreamParserState.h", @"SUPJsonString.h", @"SUPJsonStringInputStream.h", @"SUPJsonTokenIndex.h", @"SUPJsonValue.h", @"SUPJsonWriter.h", @"SUPKeyPackageName.h", @"SUPLocalEntityDelegate.h", @"SUPLocalStorage.h", @"SUPLockUtil.h", @"SUPMBOReplayStream.h", @"SUPMessageListener.h", @"SUPMessageListenerMap.h", @"SUPMessageLiterals.h", @"SUPMoBinaryJsonInputStream.h", @"SUPMoBTXUploadHandler.h", @"SUPMultipleReadWriteLock.h", @"SUPNestedTransaction.h", @"SUPNull.h", @"SUPNullDataValueException.h", @"SUPNullPointerException.h", @"SUPNumberUtil.h", @"SUPObj.h", @"SUPObjClientMessageHandler.h", @"SUPObjConnectionUtil.h", @"SUPObjDeviceConnection.h", @"SUPObjectManager.h", @"SUPObjJsonUtil.h", @"SUPObjMessageDeliverer.h", @"SUPObjServerMessageHandler.h", @"SUPObjStringLiterals.h", @"SUPOperationMap.h", @"SUPOperationMetaData.h", @"SUPOperationReplayException.h", @"SUPPackageMetaData.h", @"SUPPackageMetaDataRBS.h", @"SUPParameterMetaData.h", @"SUPPerfAgentServiceListener.h", @"SUPPersonalizationMetaData.h", @"SUPQueueConnection.h", @"SUPQueueConnectionImpl.h", @"SUPReadWriteLock.h", @"SUPReadWriteLockManager.h", @"SUPReadWriteThread.h", @"SUPRelationshipMetaData.h", @"SUPReplayLogRecord.h", @"SUPServerPersonalization.h", @"SUPServerPersonalizationDelegate.h", @"SUPServiceMap.h", @"SUPServiceMetaData.h", @"SUPSqlTrace.h", @"SUPStatementBuilder.h", @"SUPStatementBuilderRBS.h", @"SUPStatementCache.h", @"SUPStatementWrapper.h", @"SUPStreamWriter.h", @"SUPStringCache.h", @"SUPStringUtil.h", @"SUPSynchronizationGroupImpl.h", @"SUPSynchronizationRequest.h", @"SUPSynchronizationRequestQueue.h", @"SUPSyncStatusInfo.h", @"SUPThreadUtil.h", @"SUPTimeUtil.h", @"SUPUiMetaData.h", @"sybase_core.h", @"sybase_sup.h", @"CMOTestServer.h", @"DataVaultWrapper.h", @"HybridAppViewController.h", @"ListenerManager.h", @"MessagingClientLibHelper.h", @"mo_bin_protocol.h", @"moBinary.h", @"moClient.h", @"moCommon.h", @"moDateTime.h", @"moDBCommon.h", @"moErrCodes.h", @"moError.h", @"moList.h", @"moMemUtils.h", @"moOS.h", @"moParams.h", @"moRecordset.h", @"moString.h", @"moStringList.h", @"moThreadSafe.h", @"moTypes.h", @"moUtils.h", @"SUPEngine.h", @"tchar.h", @"MBODebugLogger.h", @"MBOLogger.h", @"MBOLogInterface.h", @"MclServerRmiCalls.h", @"MessagingClientLib.h", @"SUPAbstractClassException.h", @"SUPAbstractEntity.h", @"SUPAbstractEntityRBS.h", @"SUPAbstractLocalEntity.h", @"SUPAbstractLogger.h", @"SUPAbstractPackageProperties.h", @"SUPAbstractROEntity.h", @"SUPAbstractStructure.h", @"SUPAbstractSynchronizationParameters.h", @"SUPApplication.h", @"SUPApplicationCallback.h", @"SUPApplicationDefaultCallback.h", @"SUPApplicationError.h", @"SUPApplicationRuntimeException.h", @"SUPApplicationSettings.h", @"SUPApplicationTimeoutException.h", @"SUPArrayList.h", @"SUPAttributeSort.h", @"SUPAttributeTest.h", @"SUPBaseException.h", @"SUPBigBinary.h", @"SUPBigData.h", @"SUPBigObjectExceptions.h", @"SUPBigString.h", @"SUPBinaryList.h", @"SUPBinaryValue.h", @"SUPBooleanList.h", @"SUPBooleanValue.h", @"SUPBusinessObject.h", @"SUPByteList.h", @"SUPByteValue.h", @"SUPCallableComponent.h", @"SUPCallbackHandler.h", @"SUPCertificateStore.h", @"SUPChangeLog.h", @"SUPCharList.h", @"SUPCharValue.h", @"SUPColumn.h", @"SUPCompositeQuery.h", @"SUPCompositeTest.h", @"SUPConnectionProfile.h", @"SUPConnectionProperties.h", @"SUPConnectionPropertyException.h", @"SUPConnectionStatus.h", @"SUPConnectionSyncParams.h", @"SUPConnectionUtil.h", @"SUPConnectionWrapper.h", @"SUPDatabaseManager.h", @"SUPDataType.h", @"SUPDataValue.h", @"SUPDataValueList.h", @"SUPDataVault.h", @"SUPDateList.h", @"SUPDateTimeList.h", @"SUPDateTimeValue.h", @"SUPDateValue.h", @"SUPDecimalList.h", @"SUPDecimalValue.h", @"SUPDefaultCallbackHandler.h", @"SUPDefaultSyncStatusListener.h", @"SUPDeviceCondition.h", @"SUPDoubleList.h", @"SUPDoubleValue.h", @"SUPE2ETraceIllegalStateException.h", @"SUPE2ETraceLevel.h", @"SUPE2ETraceService.h", @"SUPE2ETraceServiceImpl.h", @"SUPE2ETraceUploadException.h", @"SUPEntityAlias.h", @"SUPEntityFilter.h", @"SUPEntityMessageListener.h", @"SUPError.h", @"SUPErrorCodes.h", @"SUPExceptionMessageService.h", @"SUPExceptionMessageServiceImpl.h", @"SUPFloatList.h", @"SUPFloatValue.h", @"SUPIntegerList.h", @"SUPIntegerValue.h", @"SUPIntList.h", @"SUPIntValue.h", @"SUPInvalidDataTypeException.h", @"SUPJoinCondition.h", @"SUPJoinCriteria.h", @"SUPKeyGenerator.h", @"SUPKeyGeneratorPK.h", @"SUPKeyVault.h", @"SUPLocalBusinessObject.h", @"SUPLocalKeyGenerator.h", @"SUPLocalTransaction.h", @"SUPLogger.h", @"SUPLoginCertificate.h", @"SUPLoginCredentials.h", @"SUPLoginRequiredException.h", @"SUPLogLevel.h", @"SUPLogRecord.h", @"SUPLongList.h", @"SUPLongValue.h", @"SUPMobileBusinessObject.h", @"SUPNetworkProtocol.h", @"SUPNoSuchAttributeException.h", @"SUPNoSuchClassException.h", @"SUPNoSuchOperationException.h", @"SUPNoSuchParameterException.h", @"SUPNullableBinaryList.h", @"SUPNullableBooleanList.h", @"SUPNullableByteList.h", @"SUPNullableCharList.h", @"SUPNullableDateList.h", @"SUPNullableDateTimeList.h", @"SUPNullableDecimalList.h", @"SUPNullableDoubleList.h", @"SUPNullableFloatList.h", @"SUPNullableIntegerList.h", @"SUPNullableIntList.h", @"SUPNullableLongList.h", @"SUPNullableShortList.h", @"SUPNullableStringList.h", @"SUPNullableTimeList.h", @"SUPObjectList.h", @"SUPObjectNotFoundException.h", @"SUPOnlineLoginStatus.h", @"SUPOperationReplay.h", @"SUPPerfAgentServiceImpl.h", @"SUPPerformanceAgentService.h", @"SUPPersistenceException.h", @"SUPProtocolException.h", @"SUPPushNotification.h", @"SUPQuery.h", @"SUPQueryAlias.h", @"SUPQueryResultSet.h", @"SUPRegistrationStatus.h", @"SUPResultSetWrapper.h", @"SUPSelectItem.h", @"SUPServiceRegistry.h", @"SUPShortList.h", @"SUPShortValue.h", @"SUPSISSubscription.h", @"SUPSISSubscriptionKey.h", @"SUPSortCriteria.h", @"SUPSortOrder.h", @"SUPStringList.h", @"SUPStringProperties.h", @"SUPStringValue.h", @"SUPSynchronizationAction.h", @"SUPSynchronizationContext.h", @"SUPSynchronizationGroup.h", @"SUPSynchronizationStatus.h", @"SUPSynchronizeException.h", @"SUPSynchronizeRequiredException.h", @"SUPSyncParamEntityDelegate.h", @"SUPSyncStatusListener.h", @"SUPTestCriteria.h", @"SUPTimeList.h", @"SUPTimeValue.h", @"SUPTooManyResultsException.h", @"SUPWrongDataTypeException.h", @"sybase_collections.h", @"sybase_persistence.h", @"sybase_reflection.h", @"WorkflowViewController.h", nil];
    
    NSString *updatedProjectPath = [projectPath substringToIndex:projectPath.length - [[[projectPath componentsSeparatedByString:@"/"] lastObject] length]];
    NSMutableDictionary *objectDict = [projectDict valueForKey:@"objects"];
    
    for (NSString *objectKey in objectDict.allKeys) {
        NSMutableDictionary *objectDictElem = [objectDict valueForKey:objectKey];
        if ([[objectDictElem valueForKey:@"isa"] isEqualToString:@"PBXFileReference"]  && [[objectDictElem valueForKey:@"lastKnownFileType"] rangeOfString:@"sourcecode.c"].location != NSNotFound && ([[objectDictElem valueForKey:@"path"] rangeOfString:@".m"].location != NSNotFound || [[objectDictElem valueForKey:@"path"] rangeOfString:@".h"].location != NSNotFound)) {
            @try {
                NSString *filePath = [[updatedProjectPath stringByAppendingPathComponent:[self buildReversePathForDict:objectKey intermediateResult:nil]] stringByAppendingPathComponent:[objectDictElem valueForKey:@"path"]];
                NSString *file = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
                if (file) {
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#import\\s+\"[a-zA-Z0-9\\._\\-+]*\"" options:0 error:nil];
                    NSMutableDictionary *changes = [NSMutableDictionary new];
                    for (NSTextCheckingResult *res in [regex matchesInString:file options:0 range:NSMakeRange(0, file.length)]) {
                        NSString *include = [[[[file substringWithRange:res.range] stringByReplacingOccurrencesOfString:@"#import" withString:@""] stringByReplacingOccurrencesOfString:@"\"" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        for (NSString *header in supHeaders) {
                            if ([header isEqualToString:include]) {
                                NSString *newValue = [[file substringWithRange:res.range] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"\"%@\"", include] withString:[NSString stringWithFormat:@"<%@/%@>", SUPVersion, include]];
                                [changes setValue:newValue forKey:[file substringWithRange:res.range]];
                                break;
                            }
                        }
                    }
                    for (NSString *key in changes.allKeys) {
                        file = [file stringByReplacingOccurrencesOfString:key withString:[changes valueForKey:key]];
                    }
                    [changes release];
                    [file writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                } 
            }
            @catch (NSException *exception) {
            }
        }
    }
    
}

- (void)dealloc {
    [SUPVersion release];
    [projectPath release];
    [projectDict release];
    [super dealloc];
}


@end
