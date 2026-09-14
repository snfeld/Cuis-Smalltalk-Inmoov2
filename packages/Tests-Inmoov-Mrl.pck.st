'From Cuis7.8 [latest update: #7977] on 24 August 2026'!
'Description: Unit tests for the Inmoov-Mrl package. All tests run
	against an in-image fake client (no MRL / no network required).'!
!provides: 'Tests-Inmoov-Mrl' 1 0!
!requires: 'Inmoov-Mrl' 1 0 nil!
SystemOrganization addCategory: #'Tests-Inmoov-Mrl'!


!classDefinition: #InmoovMrlClientFake category: #'Tests-Inmoov-Mrl'!
InmoovMrlClient subclass: #InmoovMrlClientFake
	instanceVariableNames: 'requests responses'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-Inmoov-Mrl'!
!classDefinition: 'InmoovMrlClientFake class' category: #'Tests-Inmoov-Mrl'!
InmoovMrlClientFake class
	instanceVariableNames: ''!

!classDefinition: #InmoovMrlClientStub category: #'Tests-Inmoov-Mrl'!
InmoovMrlClient subclass: #InmoovMrlClientStub
	instanceVariableNames: 'body'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-Inmoov-Mrl'!
!classDefinition: 'InmoovMrlClientStub class' category: #'Tests-Inmoov-Mrl'!
InmoovMrlClientStub class
	instanceVariableNames: ''!

!classDefinition: #InmoovMrlClientTest category: #'Tests-Inmoov-Mrl'!
TestCase subclass: #InmoovMrlClientTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-Inmoov-Mrl'!
!classDefinition: 'InmoovMrlClientTest class' category: #'Tests-Inmoov-Mrl'!
InmoovMrlClientTest class
	instanceVariableNames: ''!

!classDefinition: #InmoovServoGroupTest category: #'Tests-Inmoov-Mrl'!
TestCase subclass: #InmoovServoGroupTest
	instanceVariableNames: 'robot fake'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-Inmoov-Mrl'!
!classDefinition: 'InmoovServoGroupTest class' category: #'Tests-Inmoov-Mrl'!
InmoovServoGroupTest class
	instanceVariableNames: ''!

!classDefinition: #InmoovRobotTest category: #'Tests-Inmoov-Mrl'!
TestCase subclass: #InmoovRobotTest
	instanceVariableNames: 'robot fake'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-Inmoov-Mrl'!
!classDefinition: 'InmoovRobotTest class' category: #'Tests-Inmoov-Mrl'!
InmoovRobotTest class
	instanceVariableNames: ''!



!InmoovMrlClientFake methodsFor: 'initialization' stamp: 'sf 24/Aug/2026'!
initialize

	super host: 'localhost' port: 8888 robotName: 'i01'.
	requests := OrderedCollection new.
	responses := Dictionary new! !

!InmoovMrlClientFake methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
requests

	^requests! !

!InmoovMrlClientFake methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
lastRequest

	^requests last! !

!InmoovMrlClientFake methodsFor: 'configuration' stamp: 'sf 24/Aug/2026'!
respondBody: aString toMethod: methodName

	responses at: methodName put: aString! !

!InmoovMrlClientFake methodsFor: 'fake-http' stamp: 'sf 24/Aug/2026'!
getSync: serviceName method: methodName args: argsArray

	requests add: (Array with: serviceName with: methodName with: argsArray copy).
	^responses at: methodName ifAbsent: [ 'ok' ]! !

!InmoovMrlClientFake methodsFor: 'fake-http' stamp: 'sf 24/Aug/2026'!
fireAndForget: aBlock

	"Synchronous execution keeps tests deterministic."

	aBlock value! !



!InmoovMrlClientStub class methodsFor: 'instance creation' stamp: 'sf 24/Aug/2026'!
body: aString

	^self basicNew body: aString! !


!InmoovMrlClientStub methodsFor: 'initialization' stamp: 'sf 24/Aug/2026'!
body: aString

	super host: 'localhost' port: 8888 robotName: 'i01'.
	body := aString! !

!InmoovMrlClientStub methodsFor: 'fake-http' stamp: 'sf 24/Aug/2026'!
getSync: serviceName method: methodName args: argsArray

	^body! !


!InmoovMrlClientTest methodsFor: 'tests-url-building' stamp: 'sf 24/Aug/2026'!
testUrlBuildingUsesNullAndDecimalNotation

	| client url |
	client := InmoovMrlClient host: 'localhost' port: 8888 robotName: 'i01'.
	url := client serviceUrl: 'i01.rightHand' method: 'moveTo' args: {nil. 60.0}.
	self assert: url = 'http://localhost:8888/api/service/i01.rightHand/moveTo/null/60.0'! !

!InmoovMrlClientTest methodsFor: 'tests-url-building' stamp: 'sf 24/Aug/2026'!
testUrlBuildingEncodesSpaces

	| client |
	client := InmoovMrlClient host: 'localhost' port: 8888 robotName: 'i01'.
	self assert:
		(client argStringFor: 'hello world') = 'hello%20world'! !

!InmoovMrlClientTest methodsFor: 'tests-response-parsing' stamp: 'sf 24/Aug/2026'!
testNumberAtParsesFloatBody

	| client |
	client := InmoovMrlClientStub body: '45.0'.
	self assert: (client numberAt: 'x' method: 'getPos') = 45.0! !

!InmoovMrlClientTest methodsFor: 'tests-response-parsing' stamp: 'sf 24/Aug/2026'!
testNumberAtReturnsNilForNullLiteral

	| client |
	client := InmoovMrlClientStub body: 'null'.
	self assert: (client numberAt: 'x' method: 'getVelocity') isNil! !

!InmoovMrlClientTest methodsFor: 'tests-response-parsing' stamp: 'sf 24/Aug/2026'!
testBooleanAtParsesTrueAndFalse

	self assert: ((InmoovMrlClientStub body: 'true') booleanAt: 'x' method: 'isEnabled').
	self deny: ((InmoovMrlClientStub body: 'false') booleanAt: 'x' method: 'isEnabled').! !


!InmoovServoGroupTest methodsFor: 'running' stamp: 'sf 24/Aug/2026'!
setUp

	fake := InmoovMrlClientFake basicNew initialize.
	robot := InmoovRobot client: fake! !

!InmoovServoGroupTest methodsFor: 'tests-classification' stamp: 'sf 24/Aug/2026'!
testKindForClassification

	self assert: (InmoovServoGroup kindFor: 'i01.leftArm') = #arm.
	self assert: (InmoovServoGroup kindFor: 'i01.rightHand') = #hand.
	self assert: (InmoovServoGroup kindFor: 'head') = #head.
	self assert: (InmoovServoGroup kindFor: 'torso') = #torso.
	self assert: (InmoovServoGroup kindFor: 'i01.leftArm.bicep') isNil! !

!InmoovServoGroupTest methodsFor: 'tests-servo-names' stamp: 'sf 24/Aug/2026'!
testHeadServoNameListIsComplete

	| names |
	names := InmoovServoGroup servoNamesFor: #head.
	self assert: names size = 8.
	self assert: (names includes: #rollNeck).
	self assert: (names includes: #eyeX).
	self assert: (names includes: #eyeY).
	self assert: (names includes: #eyelidLeft)! !

!InmoovServoGroupTest methodsFor: 'tests-group-moves' stamp: 'sf 24/Aug/2026'!
testArmMoveSendsParameterOrderBicepRotateShoulderOmoplate

	| request |
	robot leftArm moveToBicep: 10 rotate: 20 shoulder: 30 omoplate: 40.
	request := fake lastRequest.
	self assert: request first = 'i01.leftArm'.
	self assert: request second = 'moveTo'.
	self assert: (request third at: 1) = 10.   "bicep"
	self assert: (request third at: 2) = 20.   "rotate - VOR shoulder"
	self assert: (request third at: 3) = 30.
	self assert: (request third at: 4) = 40.! !

!InmoovServoGroupTest methodsFor: 'tests-group-moves' stamp: 'sf 24/Aug/2026'!
testHandMoveWithNilLeavesOtherFingersUnchanged

	| request args |
	robot rightHand moveToThumb: nil index: 60 majeure: nil ringFinger: nil pinky: nil wrist: nil.
	request := fake lastRequest.
	args := request third.
	self assert: request first = 'i01.rightHand'.
	self assert: args size = 6.
	self assert: (args at: 1) isNil.           "thumb unveraendert"
	self assert: (args at: 2) = 60.            "index neu"! !

!InmoovServoGroupTest methodsFor: 'tests-group-moves' stamp: 'sf 24/Aug/2026'!
testEyeMoveTargetsEyeSlotsInParameterOrder

	"Head moveTo order: (neck, rothead, eyeX, eyeY, jaw, rollNeck)."

	| args |
	robot head moveToEyeX: 70 eyeY: 110.
	args := fake lastRequest third.
	self assert: (args at: 3) = 70.
	self assert: (args at: 4) = 110.
	self assert: (args at: 1) isNil.
	self assert: (args at: 6) isNil! !

!InmoovServoGroupTest methodsFor: 'tests-group-moves' stamp: 'sf 24/Aug/2026'!
testRollNeckTargetsSixthSlot

	| args |
	robot head moveToNeck: 85 rotHead: 95 rollNeck: 100.
	args := fake lastRequest third.
	self assert: (args at: 1) = 85.
	self assert: (args at: 2) = 95.
	self assert: (args at: 6) = 100! !

!InmoovServoGroupTest methodsFor: 'tests-guard-clauses' stamp: 'sf 24/Aug/2026'!
testNonArmRaisesErrorOnArmKeywordMove

	self should: [ robot torso moveToBicep: 1 rotate: 2 shoulder: 3 omoplate: 4 ]
		raise: InmoovMrlError! !

!InmoovServoGroupTest methodsFor: 'tests-children' stamp: 'sf 24/Aug/2026'!
testServoNamedBuildsDottedServiceName

	self assert:
		(robot rightHand servoNamed: #index) serviceName = 'i01.rightHand.index'.! !


!InmoovRobotTest methodsFor: 'running' stamp: 'sf 24/Aug/2026'!
setUp

	fake := InmoovMrlClientFake basicNew initialize.
	robot := InmoovRobot client: fake! !

!InmoovRobotTest methodsFor: 'tests-groups' stamp: 'sf 24/Aug/2026'!
testGroupsAreCachedPerRobot

	self assert: robot leftArm == robot leftArm.
	self assert: robot leftArm groupName = 'i01.leftArm'! !

!InmoovRobotTest methodsFor: 'tests-global' stamp: 'sf 24/Aug/2026'!
testRestAllCallsRobotRootService

	robot restAll.
	self assert: fake lastRequest first = 'i01'.
	self assert: fake lastRequest second = 'rest'.
	self assert: fake lastRequest third isEmpty! !

!InmoovRobotTest methodsFor: 'tests-gestures' stamp: 'sf 24/Aug/2026'!
testGestureIsSentAsPythonExpression

	robot performGesture: 'No()'.
	self assert: fake lastRequest first = 'i01'.
	self assert: fake lastRequest second = 'execGesture'.
	self assert: fake lastRequest third first = 'No()'! !

!
