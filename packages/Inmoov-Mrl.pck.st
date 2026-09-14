'From Cuis7.8 [latest update: #7977] on 24 August 2026'!
'Description: Asynchronous REST client API for controlling an InMoov2 robot
	running MyRobotLab (Nixie) from Cuis-Smalltalk.
	Fire & forget style per project decision doc/04-Entscheidungen.md.'!
!provides: 'Inmoov-Mrl' 1 0!
!requires: 'Network-Kernel' 1 2 nil!
!requires: 'WebClient' 1 38 nil!
SystemOrganization addCategory: #'Inmoov-Mrl'!


!classDefinition: #InmoovMrlError category: #'Inmoov-Mrl'!
Error subclass: #InmoovMrlError
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Inmoov-Mrl'!
!classDefinition: 'InmoovMrlError class' category: #'Inmoov-Mrl'!
InmoovMrlError class
	instanceVariableNames: ''!

!classDefinition: #InmoovMrlClient category: #'Inmoov-Mrl'!
Object subclass: #InmoovMrlClient
	instanceVariableNames: 'host port robotName'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Inmoov-Mrl'!
!classDefinition: 'InmoovMrlClient class' category: #'Inmoov-Mrl'!
InmoovMrlClient class
	instanceVariableNames: ''!

!classDefinition: #InmoovServo category: #'Inmoov-Mrl'!
Object subclass: #InmoovServo
	instanceVariableNames: 'client serviceName'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Inmoov-Mrl'!
!classDefinition: 'InmoovServo class' category: #'Inmoov-Mrl'!
InmoovServo class
	instanceVariableNames: ''!

!classDefinition: #InmoovServoGroup category: #'Inmoov-Mrl'!
Object subclass: #InmoovServoGroup
	instanceVariableNames: 'client groupName kind servos'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Inmoov-Mrl'!
!classDefinition: 'InmoovServoGroup class' category: #'Inmoov-Mrl'!
InmoovServoGroup class
	instanceVariableNames: ''!

!classDefinition: #InmoovRobot category: #'Inmoov-Mrl'!
Object subclass: #InmoovRobot
	instanceVariableNames: 'client groups'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Inmoov-Mrl'!
!classDefinition: 'InmoovRobot class' category: #'Inmoov-Mrl'!
InmoovRobot class
	instanceVariableNames: ''!


!InmoovMrlError commentStamp: '<historical>' prior: 0!
Raised when the MyRobotLab REST endpoint returns a non-success status
or communication fails. Fire-and-forget calls log errors to the
Transcript instead of raising.!

!InmoovMrlClient commentStamp: '<historical>' prior: 0!
Thin asynchronous HTTP client for the MyRobotLab Service REST API
(http://host:port/api/service/{name}/{method}/{args}).

Movement-style calls use fire & forget (background fork); query calls
(getSync...) are synchronous and return strings or numbers. Uses the
GET path form because MRL decodes those parameters against the real
method signature (POST bodies are NOT type-decoded - see research/06).!

!InmoovServo commentStamp: '<historical>' prior: 0!
Handle for one MRL servo service, e.g. i01.rightHand.index.
All movement methods are fire & forget and return self;
query methods are synchronous.!

!InmoovServoGroup commentStamp: '<historical>' prior: 0!
Handle for an MRL group service (i01.leftArm, i01.leftHand, i01.head,
i01.torso ...). Group moves address the group service directly because
the Integer overloads of moveLeftHand/moveRightHand crash on nil
arguments (see research/06). nil argument means "do not change".!

!InmoovRobot commentStamp: '<historical>' prior: 0!
Facade for one named InMoov2 robot (default i01) reachable through an
InmoovMrlClient. Gives access to servo groups and single servos,
plus global operations (rest all, availability check).!


!InmoovMrlClient class methodsFor: 'instance creation' stamp: 'sf 24/Aug/2026'!
host: hostString port: portInteger robotName: nameString

	^self basicNew host: hostString port: portInteger robotName: nameString! !


!InmoovMrlClient methodsFor: 'initialization' stamp: 'sf 24/Aug/2026'!
host: hostString port: portInteger robotName: nameString

	host := hostString.
	port := portInteger.
	robotName := nameString! !

!InmoovMrlClient methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
host

	^host! !

!InmoovMrlClient methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
port

	^port! !

!InmoovMrlClient methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
robotName

	^robotName! !

!InmoovMrlClient methodsFor: 'private-url' stamp: 'sf 24/Aug/2026'!
serviceUrl: serviceName method: methodName

	"Base URL without path parameters (POST body carries the args)."

	^'http://', host, ':', port printString, '/api/service/', serviceName, '/', methodName! !

!InmoovMrlClient methodsFor: 'private-url' stamp: 'sf 24/Aug/2026'!
serviceUrl: serviceName method: methodName args: argsArray

	| url |
	url := String streamContents: [ :strm |
		strm nextPutAll: (self serviceUrl: serviceName method: methodName).
		argsArray do: [ :each |
			strm nextPut: $/.
			each isNil
				ifTrue: [ strm nextPutAll: 'null' ]
				ifFalse: [ strm nextPutAll: (self argStringFor: each) ]]].
	^url! !

!InmoovMrlClient methodsFor: 'private-url' stamp: 'sf 29/Aug/2026'!
jsonArrayStringFor: argsArray

	"Minimal JSON serialization of a smalltalk array into a JSON array
	literal for POST bodies. Handles nil, booleans, numbers and strings
	(quotes and backslashes escaped). Response bodies (like the string
	None that MRL returns) are passed through untouched."

	^String streamContents: [ :strm |
		strm nextPut: $[.
		argsArray withIndexDo: [ :each :i |
			i > 1 ifTrue: [ strm nextPut: $, ].
			each isNil
				ifTrue: [ strm nextPutAll: 'null' ]
				ifFalse: [
					each == true
						ifTrue: [ strm nextPutAll: 'true' ]
						ifFalse: [
							each == false
								ifTrue: [ strm nextPutAll: 'false' ]
								ifFalse: [
									each isNumber
										ifTrue: [ strm nextPutAll: each printString ]
										ifFalse: [
											strm nextPut: (Character codePoint: 34).
											each asString do: [ :ch |
												ch == (Character codePoint: 34)
													ifTrue: [ strm nextPutAll: '\\' ; nextPut: (Character codePoint: 34) ]
													ifFalse: [
														ch == $\
															ifTrue: [ strm nextPutAll: '\\\\' ]
															ifFalse: [
																ch == Character lf
																	ifTrue: [ strm nextPutAll: '\n' ]
																	ifFalse: [
																		ch == Character cr
																			ifTrue: [ strm nextPutAll: '\r' ]
																			ifFalse: [ strm nextPut: ch ] ] ] ] ].
											strm nextPut: (Character codePoint: 34) ] ] ] ] ].
		strm nextPut: $] ]! !

!InmoovMrlClient methodsFor: 'private-url' stamp: 'sf 24/Aug/2026'!
argStringFor: anArgument

	anArgument == true ifTrue: [ ^'true' ].
	anArgument == false ifTrue: [ ^'false' ].
	anArgument isNumber ifTrue: [ ^anArgument printString ].
	^anArgument asString copyReplaceAll: ' ' with: '%20'! !

!InmoovMrlClient methodsFor: 'requests-sync' stamp: 'sf 24/Aug/2026'!
getSync: serviceName method: methodName args: argsArray

	| response url |
	url := self serviceUrl: serviceName method: methodName args: argsArray.
	[
		response := WebClient httpGet: url
	] on: Error do: [ :ex |
		InmoovMrlError signal: 'HTTP failure at ', url, ': ', ex messageText ].
	(response code between: 200 and: 299) ifFalse: [
		InmoovMrlError signal:
			('MRL HTTP <1p> at <2s>: <3s>'
				expandMacrosWith: response code
				with: url
				with: (response content ifNil: ['']) withBlanksTrimmed) ].
	^response content! !

!InmoovMrlClient methodsFor: 'requests-sync' stamp: 'sf 26/Aug/2026'!
postSync: serviceName method: methodName jsonString: jsonString

	"Synchronous POST. The jsonString is the whole JSON-array body
	(see jsonArrayStringFor:); execGesture and speak do NOT work
	reliably via the GET path (MRL's Jackson raises
	'Unrecognized token' for values like 'No()' that are not valid
	JSON on their own)."

	| response url |
	url := self serviceUrl: serviceName method: methodName.
	[
		response := WebClient httpPost: url content: jsonString type: 'application/json'
	] on: Error do: [ :ex |
		InmoovMrlError signal: 'HTTP failure at ', url, ': ', ex messageText ].
	(response code between: 200 and: 299) ifFalse: [
		InmoovMrlError signal:
			('MRL HTTP <1p> at <2s>: <3s>'
				expandMacrosWith: response code
				with: url
				with: (response content ifNil: ['']) withBlanksTrimmed) ].
	^response content! !

!InmoovMrlClient methodsFor: 'requests-sync' stamp: 'sf 24/Aug/2026'!
numberAt: serviceName method: methodName

	| body |
	body := self getSync: serviceName method: methodName args: #().
	(body isNil or: [ body withBlanksTrimmed = 'null' ]) ifTrue: [ ^nil ].
	^Number readFrom: body withBlanksTrimmed! !

!InmoovMrlClient methodsFor: 'requests-sync' stamp: 'sf 24/Aug/2026'!
booleanAt: serviceName method: methodName

	| body |
	body := self getSync: serviceName method: methodName args: #().
	^body withBlanksTrimmed = 'true'! !

!InmoovMrlClient methodsFor: 'requests-async' stamp: 'sf 24/Aug/2026'!
fireAndForget: aBlock

	"Run aBlock in the background; errors go to the Transcript."

	[
		[ aBlock value ]
			on: Error do: [ :ex |
				Transcript showLine: '[InMoov] fire&forget failure: ', ex messageText ]
	] forkAt: Processor userBackgroundPriority! !

!InmoovMrlClient methodsFor: 'requests-async' stamp: 'sf 24/Aug/2026'!
callService: serviceName method: methodName args: argsArray

	self fireAndForget: [ self getSync: serviceName method: methodName args: argsArray ]! !

!InmoovMrlClient methodsFor: 'requests-async' stamp: 'sf 26/Aug/2026'!
callServiceWithJson: serviceName method: methodName jsonString: jsonString

	self fireAndForget: [ self postSync: serviceName method: methodName jsonString: jsonString ]! !

!InmoovMrlClient methodsFor: 'queries' stamp: 'sf 24/Aug/2026'!
uptime

	^self getSync: 'runtime' method: 'getUptime' args: #()! !


!InmoovServo class methodsFor: 'instance creation' stamp: 'sf 24/Aug/2026'!
client: aClient serviceName: aString

	^self basicNew client: aClient serviceName: aString! !


!InmoovServo methodsFor: 'initialization' stamp: 'sf 24/Aug/2026'!
client: aClient serviceName: aString

	client := aClient.
	serviceName := aString! !

!InmoovServo methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
client

	^client! !

!InmoovServo methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
serviceName

	^serviceName! !

!InmoovServo methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
moveTo: degrees

	client callService: serviceName method: 'moveTo' args: {degrees}.
	^self! !

!InmoovServo methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
setVelocity: degreesPerSecond

	client callService: serviceName method: 'setVelocity' args: {degreesPerSecond}.
	^self! !

!InmoovServo methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
rest

	client callService: serviceName method: 'rest' args: #().
	^self! !

!InmoovServo methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
enable

	client callService: serviceName method: 'enable' args: #().
	^self! !

!InmoovServo methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
disable

	client callService: serviceName method: 'disable' args: #().
	^self! !

!InmoovServo methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
position

	^client numberAt: serviceName method: 'getPos'! !

!InmoovServo methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
targetPosition

	^client numberAt: serviceName method: 'getTargetPos'! !

!InmoovServo methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
minValue

	^client numberAt: serviceName method: 'getMin'! !

!InmoovServo methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
maxValue

	^client numberAt: serviceName method: 'getMax'! !

!InmoovServo methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
restValue

	^client numberAt: serviceName method: 'getRest'! !

!InmoovServo methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
velocity

	^client numberAt: serviceName method: 'getVelocity'! !

!InmoovServo methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
isInverted

	^client booleanAt: serviceName method: 'isInverted'! !

!InmoovServo methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
isEnabled

	^client booleanAt: serviceName method: 'isEnabled'! !

!InmoovServo methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
statusDictionary

	"Consolidated configuration + status snapshot for this servo."

	| report |
	report := Dictionary new.
	#(position targetPosition minValue maxValue restValue velocity isInverted isEnabled)
		do: [ :each | report at: each put: (self perform: each) ].
	^report! !


!InmoovServoGroup class methodsFor: 'instance creation' stamp: 'sf 24/Aug/2026'!
client: aClient groupName: aString

	^self basicNew client: aClient groupName: aString! !

!InmoovServoGroup class methodsFor: 'classification' stamp: 'sf 24/Aug/2026'!
kindFor: groupNameString

	| idx short |
	idx := 0.
	1 to: groupNameString size do: [ :i |
		(groupNameString at: i) = $. ifTrue: [ idx := i ] ].
	short := idx = 0
		ifTrue: [ groupNameString ]
		ifFalse: [ groupNameString copyFrom: idx + 1 to: groupNameString size ].
	short = 'leftArm' ifTrue: [ ^#arm ].
	short = 'rightArm' ifTrue: [ ^#arm ].
	short = 'leftHand' ifTrue: [ ^#hand ].
	short = 'rightHand' ifTrue: [ ^#hand ].
	short = 'head' ifTrue: [ ^#head ].
	short = 'torso' ifTrue: [ ^#torso ].
	^nil! !

!InmoovServoGroup class methodsFor: 'classification' stamp: 'sf 24/Aug/2026'!
servoNamesFor: aKindSymbol

	aKindSymbol = #arm ifTrue: [ ^#(bicep rotate shoulder omoplate) ].
	aKindSymbol = #hand ifTrue: [ ^#(thumb index majeure ringFinger pinky wrist) ].
	aKindSymbol = #head ifTrue: [ ^#(neck rothead rollNeck jaw eyeX eyeY eyelidLeft eyelidRight) ].
	aKindSymbol = #torso ifTrue: [ ^#(topStom midStom lowStom) ].
	^#()! !


!InmoovServoGroup methodsFor: 'initialization' stamp: 'sf 24/Aug/2026'!
client: aClient groupName: aString

	client := aClient.
	groupName := aString.
	kind := self class kindFor: aString.
	servos := Dictionary new! !

!InmoovServoGroup methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
groupName

	^groupName! !

!InmoovServoGroup methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
kind

	^kind! !

!InmoovServoGroup methodsFor: 'children' stamp: 'sf 24/Aug/2026'!
servoNamed: nameSymbol

	| key |
	key := nameSymbol asString.
	^servos
		at: key
		ifAbsentPut: [ InmoovServo client: client serviceName: groupName, '.', key ]! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
moveToArgs: argumentsArray

	"Generic group move. nil elements mean 'leave this servo unchanged'.
	Sends directly to the group service (avoids the Integer-overload NPE
	of moveLeftHand/moveRightHand on i01 - see research/06)."

	client callService: groupName method: 'moveTo' args: argumentsArray.
	^self! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
moveToBicep: bicep rotate: rotate shoulder: shoulder omoplate: omoplate

	kind = #arm ifFalse: [ InmoovMrlError signal: groupName, ' is not an arm' ].
	^self moveToArgs: {bicep. rotate. shoulder. omoplate}! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
moveToThumb: thumb index: index majeure: majeure ringFinger: ringFinger pinky: pinky wrist: wrist

	kind = #hand ifFalse: [ InmoovMrlError signal: groupName, ' is not a hand' ].
	^self moveToArgs: {thumb. index. majeure. ringFinger. pinky. wrist}! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
moveToThumb: thumb index: index majeure: majeure ringFinger: ringFinger pinky: pinky

	^self moveToThumb: thumb index: index majeure: majeure ringFinger: ringFinger pinky: pinky wrist: nil! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
moveToNeck: neck rotHead: rotHead

	kind = #head ifFalse: [ InmoovMrlError signal: groupName, ' is not a head' ].
	^self moveToArgs: {neck. rotHead}! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
moveToEyeX: eyeX eyeY: eyeY

	"Head moveTo parameter order: (neck, rothead, eyeX, eyeY, jaw,
	rollNeck) - see InMoov2Head.moveTo."

	kind = #head ifFalse: [ InmoovMrlError signal: groupName, ' is not a head' ].
	^self moveToArgs: {nil. nil. eyeX. eyeY. nil. nil}! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
moveToNeck: neck rotHead: rotHead rollNeck: rollNeck

	kind = #head ifFalse: [ InmoovMrlError signal: groupName, ' is not a head' ].
	^self moveToArgs: {neck. rotHead. nil. nil. nil. rollNeck}! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
moveToTopStom: topStom midStom: midStom lowStom: lowStom

	kind = #torso ifFalse: [ InmoovMrlError signal: groupName, ' is not a torso' ].
	^self moveToArgs: {topStom. midStom. lowStom}! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
rest

	client callService: groupName method: 'rest' args: #().
	^self! !

!InmoovServoGroup methodsFor: 'operations-fire-forget' stamp: 'sf 24/Aug/2026'!
setVelocity: degreesPerSecond

	client callService: groupName method: 'setVelocity' args: {degreesPerSecond}.
	^self! !

!InmoovServoGroup methodsFor: 'queries-sync' stamp: 'sf 24/Aug/2026'!
statusReport

	"Dictionary servoName -> statusDictionary. Servos that are not
	running (not started as peers) are silently skipped."

	| report |
	report := Dictionary new.
	(self class servoNamesFor: kind) do: [ :each |
		[
			report
				at: each asSymbol
				put: (self servoNamed: each asSymbol) statusDictionary
		] on: Error do: [ :ex | "servo missing - skip" ] ].
	^report! !


!InmoovRobot class methodsFor: 'instance creation' stamp: 'sf 24/Aug/2026'!
host: hostString port: portInteger robotName: nameString

	^self basicNew
		client: (InmoovMrlClient host: hostString port: portInteger robotName: nameString)! !

!InmoovRobot class methodsFor: 'instance creation' stamp: 'sf 24/Aug/2026'!
client: anInmoovMrlClient

	"Dependency-injection entry point for tests (fake clients)."

	^self basicNew client: anInmoovMrlClient! !


!InmoovRobot methodsFor: 'initialization' stamp: 'sf 24/Aug/2026'!
client: anInmoovMrlClient

	client := anInmoovMrlClient.
	groups := Dictionary new! !

!InmoovRobot methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
client

	^client! !

!InmoovRobot methodsFor: 'groups' stamp: 'sf 24/Aug/2026'!
groupNamed: shortGroupName

	| fullName |
	fullName := client robotName, '.', shortGroupName asString.
	^groups at: fullName ifAbsentPut: [ InmoovServoGroup client: client groupName: fullName ]! !

!InmoovRobot methodsFor: 'groups' stamp: 'sf 24/Aug/2026'!
leftArm

	^self groupNamed: 'leftArm'! !

!InmoovRobot methodsFor: 'groups' stamp: 'sf 24/Aug/2026'!
rightArm

	^self groupNamed: 'rightArm'! !

!InmoovRobot methodsFor: 'groups' stamp: 'sf 24/Aug/2026'!
leftHand

	^self groupNamed: 'leftHand'! !

!InmoovRobot methodsFor: 'groups' stamp: 'sf 24/Aug/2026'!
rightHand

	^self groupNamed: 'rightHand'! !

!InmoovRobot methodsFor: 'groups' stamp: 'sf 24/Aug/2026'!
head

	^self groupNamed: 'head'! !

!InmoovRobot methodsFor: 'groups' stamp: 'sf 24/Aug/2026'!
torso

	^self groupNamed: 'torso'! !

!InmoovRobot methodsFor: 'global' stamp: 'sf 24/Aug/2026'!
restAll

	"Send every servo to its configured rest position."

	client callService: client robotName method: 'rest' args: #().
	^self! !

!InmoovRobot methodsFor: 'global' stamp: 'sf 24/Aug/2026'!
isAvailable

	"True if the robot answers a simple servo query."

	^[
		(client getSync: client robotName, '.leftArm.bicep' method: 'getRest' args: #()) notNil
	] on: Error do: [ :ex | false ]! !

!InmoovRobot methodsFor: 'global' stamp: 'sf 24/Aug/2026'!
uptime

	^client uptime! !

!InmoovRobot methodsFor: 'global' stamp: 'sf 24/Aug/2026'!
statusReport

	"Dictionary groupNameSymbol -> (Dictionary servoName -> status)."

	| report |
	report := Dictionary new.
	#(leftArm rightArm leftHand rightHand head torso) do: [ :each |
		report at: each put: (self groupNamed: each) statusReport ].
	^report! !

!InmoovRobot methodsFor: 'gestures' stamp: 'sf 26/Aug/2026'!
performGesture: gestureExpression

	"Fire & forget. The expression is Python code executed by the MRL
	python service, e.g. 'No()' or 'EyeMovements()' (file name of the
	gesture script minus .py, plus parentheses). Requires a started
	'python' service (myrobotlab.sh starts one by default).
	Sent via POST with a JSON body: the GET path makes MRL's Jackson
	raise 'Unrecognized token' for expressions like 'No()'."

	client callServiceWithJson: client robotName method: 'execGesture'
		jsonString: (client jsonArrayStringFor: {gestureExpression}).
	^self! !

!InmoovRobot methodsFor: 'gestures' stamp: 'sf 26/Aug/2026'!
performGestureWait: gestureExpression

	"Synchronous variant; answers execGesture's result string
	(nil if the python service is not running). POST + JSON body,
	see performGesture:."

	^client postSync: client robotName method: 'execGesture'
		jsonString: (client jsonArrayStringFor: {gestureExpression})! !

!InmoovRobot class methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestureListingSource

	"Single-line python helper for MRL's python service. Answers the
	sorted names of all gesture scripts (resource/InMoov2/gestures/*.py,
	filename minus .py) joined with ';'. No newlines needed, so it works
	as a JSON-body string. All python string literals use SINGLE quotes so
	the payload contains no double quotes: even naive (unescaped) JSON
	builders like ['<code>'] stay valid for MRL's Jackson (it rejects
	unescaped double quotes at the array level with 'was expecting comma
	to separate Array entries'). Redefining it on every call is idempotent
	and survives MRL restarts by construction (see Research: no dedicated
	listGestures REST endpoint exists - this is the working equivalent)."

	^'def _cuiGestures(): return '';''.join(sorted(f[:-3] for f in __import__(''os'').listdir(''resource/InMoov2/gestures'') if f.endswith(''.py'')))'! !

!InmoovRobot class methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestureNamesFromRawBody: rawBody

	"MRL answers python/eval with a JSON string literal: the names joined
	with ';' and surrounded by double quotes. Strip the quotes and split.
	Answers an OrderedCollection of gesture names (without '.py', without
	the trailing '()' that performGesture: needs)."

	| trimmed |
	trimmed := rawBody ifNil: [ '' ] ifNotNil: [ rawBody withBlanksTrimmed ].
	(trimmed = 'null' or: [ trimmed isEmpty ]) ifTrue: [ ^OrderedCollection new ].
	(trimmed size >= 2 and: [ trimmed first = $" and: [ trimmed last = $" ]])
		ifTrue: [ trimmed := trimmed copyFrom: 2 to: trimmed size - 1 ].
	^(trimmed findTokens: ';') reject: [ :each | each isEmpty ]! !

!InmoovRobot methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestureNamesSync

	"Synchronous variant: defines the list helper in the MRL python
	service, evals it and answers the sorted gesture names. Blocks until
	MRL replied (two round trips). Prefer gestureNamesOnDone:onError: in
	UI code."

	| raw |
	client postSync: 'python' method: 'exec'
		jsonString: (client jsonArrayStringFor: {self class gestureListingSource}).
	raw := client postSync: 'python' method: 'eval'
		jsonString: (client jsonArrayStringFor: {'_cuiGestures'}).
	^self class gestureNamesFromRawBody: raw! !

!InmoovRobot methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestureNamesOnDone: doneBlock onError: errorBlock

	"Fire & forget. Loads the available gesture names in a background
	process and answers them to doneBlock (OrderedCollection); HTTP or
	parse problems go to errorBlock (Exception). The UI must not touch
	the world from the callback without UISupervisor whenUIinSafeState:."

	[
		[ doneBlock value: self gestureNamesSync ]
			on: Error do: [ :ex | errorBlock value: ex ]
	] forkAt: Processor userBackgroundPriority named: 'InMoov gesture list'! !

!InmoovRobot methodsFor: 'speech' stamp: 'sf 26/Aug/2026'!
speak: aString

	"Speak via the i01.mouth peer (speech synthesis). Fire & forget:
	body movements can run in parallel. No-op if mouth is not started."

	client callServiceWithJson: client robotName method: 'speak'
		jsonString: (client jsonArrayStringFor: {aString}).
	^self! !

!InmoovRobot methodsFor: 'speech' stamp: 'sf 26/Aug/2026'!
speakBlocking: aString

	"Synchronous variant: blocks until the audio service finished
	speaking, then answers the raw response content. See speak:."

	^client postSync: client robotName method: 'speakBlocking'
		jsonString: (client jsonArrayStringFor: {aString})! !


"Postscript:

First working milestone-1 version of the InMoov2/MRL REST client API.
Verified live against MRL 1.1.1610 in virtual mode (research/06).
"!
