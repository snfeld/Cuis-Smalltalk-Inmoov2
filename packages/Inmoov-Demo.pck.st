'From Cuis7.8 [latest update: #7977] on 24 August 2026'!
'Description: Small demo UI for the InMoov-Mrl client: one window with
	a group selector, one slider per servo (range taken from the live
	min/max configuration), rest buttons and a polled status line.'!
!provides: 'Inmoov-Demo' 1 0!
!requires: 'Inmoov-Mrl' 1 0 nil!
SystemOrganization addCategory: #'Inmoov-Demo'!


!classDefinition: #InmoovSliderMorph category: #'Inmoov-Demo'!
BorderedBoxMorph subclass: #InmoovSliderMorph
	instanceVariableNames: 'minValue maxValue value labelText labelFont changeBlock commitBlock'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Inmoov-Demo'!
!classDefinition: 'InmoovSliderMorph class' category: #'Inmoov-Demo'!
InmoovSliderMorph class
	instanceVariableNames: ''!

!classDefinition: #InmoovStatusLabel category: #'Inmoov-Demo'!
BorderedBoxMorph subclass: #InmoovStatusLabel
	instanceVariableNames: 'text font'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Inmoov-Demo'!
!classDefinition: 'InmoovStatusLabel class' category: #'Inmoov-Demo'!
InmoovStatusLabel class
	instanceVariableNames: ''!

!classDefinition: #InmoovServoDemoWindow category: #'Inmoov-Demo'!
SystemWindow subclass: #InmoovServoDemoWindow
	instanceVariableNames: 'robot currentGroup rowsPane statusLabel pollProcess lastSent gestures gestureList gestureHint gestureListIndex'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Inmoov-Demo'!
!classDefinition: 'InmoovServoDemoWindow class' category: #'Inmoov-Demo'!
InmoovServoDemoWindow class
	instanceVariableNames: ''!


!InmoovSliderMorph commentStamp: '<historical>' prior: 0!
Minimal horizontal slider for the servo demo. Reports continuous value
changes while dragging (change block) plus a guaranteed final report on
mouse up (commit block), so no throttled intermediate value gets lost.!


!InmoovSliderMorph class methodsFor: 'constants' stamp: 'sf 24/Aug/2026'!
padding

	^10! !

!InmoovSliderMorph class methodsFor: 'constants' stamp: 'sf 24/Aug/2026'!
knobExtent

	^18! !


!InmoovSliderMorph methodsFor: 'initialization' stamp: 'sf 24/Aug/2026'!
initialize

	super initialize.
	minValue := 0.0.
	maxValue := 180.0.
	value := 0.0.
	labelText := ''.
	self morphExtent: 220@30! !

!InmoovSliderMorph methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
labelText: aString

	labelText := aString.
	self redrawNeeded! !

!InmoovSliderMorph methodsFor: 'private' stamp: 'sf 26/Aug/2026'!
labelFont

	"Smaller than the default label font so the servo name fits into
	the top band of the slider without being covered by the knob."

	^labelFont ifNil: [ labelFont := FontFamily defaultFamilyPointSize: 11 ]! !

!InmoovSliderMorph methodsFor: 'classification' stamp: 'sf 24/Aug/2026'!
is: aSymbol

	^aSymbol == #InmoovSliderMorph or: [ super is: aSymbol ]! !

!InmoovSliderMorph methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
value

	^value! !

!InmoovSliderMorph methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
minValue

	^minValue! !

!InmoovSliderMorph methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
maxValue

	^maxValue! !

!InmoovSliderMorph methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
minValue: aNumber

	minValue := aNumber.
	self redrawNeeded! !

!InmoovSliderMorph methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
maxValue: aNumber

	maxValue := aNumber.
	self redrawNeeded! !

!InmoovSliderMorph methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
initialValue: aNumber

	value := (aNumber max: minValue) min: maxValue.
	self redrawNeeded! !

!InmoovSliderMorph methodsFor: 'events-registering' stamp: 'sf 24/Aug/2026'!
whenValueChangedDo: aBlock

	changeBlock := aBlock! !

!InmoovSliderMorph methodsFor: 'events-registering' stamp: 'sf 24/Aug/2026'!
whenInteractionEndsDo: aBlock

	commitBlock := aBlock! !

!InmoovSliderMorph methodsFor: 'events-processing' stamp: 'sf 24/Aug/2026'!
handlesMouseDown: aMouseButtonEvent

	^true! !

!InmoovSliderMorph methodsFor: 'events-processing' stamp: 'sf 24/Aug/2026'!
mouseButton1Down: aMouseButtonEvent localPosition: localEventPosition

	aMouseButtonEvent hand newMouseFocus: self.
	self updateFromLocalPosition: localEventPosition! !

!InmoovSliderMorph methodsFor: 'events-processing' stamp: 'sf 24/Aug/2026'!
mouseMove: aMouseMoveEvent localPosition: localEventPosition

	aMouseMoveEvent anyButtonPressed
		ifTrue: [ self updateFromLocalPosition: localEventPosition ]! !

!InmoovSliderMorph methodsFor: 'events-processing' stamp: 'sf 24/Aug/2026'!
mouseButton1Up: aMouseButtonEvent localPosition: localEventPosition

	aMouseButtonEvent hand newMouseFocus: nil.
	self updateFromLocalPosition: localEventPosition.
	commitBlock ifNotNil: [ commitBlock value: value ]! !

!InmoovSliderMorph methodsFor: 'private' stamp: 'sf 24/Aug/2026'!
setValue: aNumber

	| clamped |
	clamped := (aNumber max: minValue) min: maxValue.
	clamped = value ifFalse: [
		value := clamped.
		self redrawNeeded ].
	changeBlock ifNotNil: [ changeBlock value: value ].
	^value! !

!InmoovSliderMorph methodsFor: 'private' stamp: 'sf 24/Aug/2026'!
updateFromLocalPosition: aPoint

	| trackLength ratio |
	trackLength := self morphWidth - (2 * self class padding) - self class knobExtent.
	trackLength <= 0 ifTrue: [ ^self ].
	ratio := (aPoint x - self class padding - (self class knobExtent / 2)) / trackLength.
	ratio := ratio min: 1.0 max: 0.0.
	self setValue: minValue + (ratio * (maxValue - minValue))! !

!InmoovSliderMorph methodsFor: 'drawing' stamp: 'sf 26/Aug/2026'!
drawOn: aCanvas

	"Clean position indicator: servo name in the top band, a thin
	progress track at the bottom and a knob that is always clamped to
	the track so nothing is ever drawn beyond the slider (or window)
	bounds."

	| bounds barRect knobX filledRect knobRect trackCenterY minKnobX maxKnobX ratio |
	super drawOn: aCanvas.
	bounds := self localBounds.
	labelText notEmpty ifTrue: [
		aCanvas
			drawString: labelText
			at: (bounds left + self class padding) @ (bounds top + 1)
			font: self labelFont
			color: Color darkGray ].
	trackCenterY := bounds bottom - 9.
	barRect := (bounds left + self class padding)
			@ (trackCenterY - 2 rounded)
		corner: (bounds right - self class padding)
			@ (trackCenterY + 2 rounded).
	minKnobX := bounds left + self class padding + (self class knobExtent / 2).
	maxKnobX := bounds right - self class padding - (self class knobExtent / 2).
	knobX := minKnobX.
	maxValue > minValue ifTrue: [
		ratio := (value - minValue) / (maxValue - minValue).
		ratio := ratio min: 1.0 max: 0.0.
		knobX := minKnobX + (ratio * (maxKnobX - minKnobX)) ].
	filledRect := barRect topLeft corner: knobX @ barRect bottom.
	filledRect width > 0 ifTrue: [
		aCanvas fillRectangle: filledRect color: Color gray ].
	aCanvas fillRectangle: barRect color: Color veryLightGray.
	knobRect := (knobX - (self class knobExtent / 2))
			@ (trackCenterY - 7)
		corner: (knobX + (self class knobExtent / 2))
			@ (trackCenterY + 7).
	aCanvas fillRectangle: (knobRect outsetBy: 2) color: (Color gray: 0.8).
	aCanvas fillRectangle: knobRect color: Color black! !


!InmoovStatusLabel commentStamp: '<historical>' prior: 0!
Wraps the polled status text over multiple lines using a small font,
so a long report never forces the demo window to grow horizontally.!


!InmoovStatusLabel methodsFor: 'initialization' stamp: 'sf 26/Aug/2026'!
initialize

	super initialize.
	borderWidth := 0.
	color := Color transparent.
	text := ''.
	font := FontFamily defaultFamilyPointSize: 10! !

!InmoovStatusLabel methodsFor: 'accessing' stamp: 'sf 26/Aug/2026'!
contents: aString

	text := aString.
	self redrawNeeded! !

!InmoovStatusLabel methodsFor: 'accessing' stamp: 'sf 26/Aug/2026'!
contents

	^text! !

!InmoovStatusLabel methodsFor: 'accessing' stamp: 'sf 26/Aug/2026'!
font

	^font! !

!InmoovStatusLabel methodsFor: 'drawing' stamp: 'sf 26/Aug/2026'!
drawOn: aCanvas

	| bounds words lines current |
	super drawOn: aCanvas.
	bounds := self localBounds.
	text isEmpty ifTrue: [ ^self ].
	words := text findTokens: ' '.
	lines := OrderedCollection new.
	current := ''.
	words do: [ :word |
		| candidate |
		candidate := current isEmpty ifTrue: [ word ] ifFalse: [ current, ' ', word ].
		(font widthOfString: candidate) <= (bounds width - 4)
			ifTrue: [ current := candidate ]
			ifFalse: [ lines add: current. current := word ] ].
	lines add: current.
	lines withIndexDo: [ :line :index |
		aCanvas
			drawString: line
			at: (bounds left + 2) @ (bounds top + ((index - 1) * font lineSpacing rounded))
			font: font
			color: Color darkGray ]! !


!InmoovServoDemoWindow class methodsFor: 'constants' stamp: 'sf 29/Aug/2026'!
preferredWidth

	"Wide enough for the servo controls (left) plus the gesture panel
	(list + buttons, see gesturePanelWidth)."

	^900! !

!InmoovServoDemoWindow class methodsFor: 'constants' stamp: 'sf 29/Aug/2026'!
gesturePanelWidth

	^320! !

!InmoovServoDemoWindow class methodsFor: 'constants' stamp: 'sf 24/Aug/2026'!
sliderRowHeight

	"Height of one slider row including its share of separation."

	^34! !

!InmoovServoDemoWindow class methodsFor: 'constants' stamp: 'sf 24/Aug/2026'!
sliderHeight

	^30! !

!InmoovServoDemoWindow class methodsFor: 'constants' stamp: 'sf 24/Aug/2026'!
buttonRowHeight

	^34! !

!InmoovServoDemoWindow class methodsFor: 'constants' stamp: 'sf 24/Aug/2026'!
bottomRowHeight

	"Tall enough for three wrapped status lines (10 pt font)."

	^48! !


!InmoovServoDemoWindow class methodsFor: 'instance creation' stamp: 'sf 24/Aug/2026'!
openOn: anInmoovRobot

	| window |
	window := self new robot: anInmoovRobot.
	window setLabel: 'InMoov Servo Demo'.
	window openInWorld.
	^window! !


!InmoovServoDemoWindow methodsFor: 'initialization' stamp: 'sf 29/Aug/2026'!
initialize

	super initialize.
	lastSent := Dictionary new.
	gestures := OrderedCollection new.
	gestureListIndex := 0.
	rowsPane := LayoutMorph newColumn separation: 4.
	statusLabel := InmoovStatusLabel new.
	gestureHint := InmoovStatusLabel new! !

!InmoovServoDemoWindow methodsFor: 'initialization' stamp: 'sf 29/Aug/2026'!
robot: anInmoovRobot

	robot := anInmoovRobot.
	self buildWidgets.
	self selectGroupNamed: #leftArm.
	self refreshGestures.
	self startPolling! !

!InmoovServoDemoWindow methodsFor: 'accessing' stamp: 'sf 24/Aug/2026'!
robot

	^robot! !

!InmoovServoDemoWindow methodsFor: 'gui-building' stamp: 'sf 29/Aug/2026'!
buildWidgets

	"Body layout: one row of two columns - the servo controls on the
	left, the gesture panel on the right (see buildGesturePanel)."

	| bodyRow leftColumn topRow bottomRow |
	topRow := LayoutMorph newRow separation: 4.
	#(leftArm leftHand head rightArm rightHand torso) do: [ :each |
		| btn |
		btn := PluggableButtonMorph
				model: self
				action: ('select', each capitalized) asSymbol
				label: (self labelForGroup: each).
		btn morphExtent: 60 @ self class sliderHeight.
		topRow
			addMorph: btn
			layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class sliderHeight) ].
	bottomRow := LayoutMorph newRow separation: 8.
	bottomRow
		addMorph:
			(PluggableButtonMorph model: self action: #restCurrentGroup label: 'Rest Gruppe')
		layoutSpec: (LayoutSpec fixedWidth: 110 fixedHeight: self class sliderHeight).
	bottomRow
		addMorph:
			(PluggableButtonMorph model: self action: #restAll label: 'Rest ALLES')
		layoutSpec: (LayoutSpec fixedWidth: 110 fixedHeight: self class sliderHeight).
	bottomRow
		addMorph: statusLabel
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class bottomRowHeight).
	leftColumn := LayoutMorph newColumn separation: 4.
	leftColumn
		addMorph: topRow
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class buttonRowHeight).
	leftColumn
		addMorph: rowsPane
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 proportionalHeight: 1.0).
	leftColumn
		addMorph: bottomRow
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class bottomRowHeight).
	bodyRow := LayoutMorph newRow separation: 8.
	bodyRow
		addMorph: leftColumn
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 proportionalHeight: 1.0).
	bodyRow
		addMorph: self buildGesturePanel
		layoutSpec: (LayoutSpec fixedWidth: self class gesturePanelWidth proportionalHeight: 1.0).
	self layoutMorph
		addMorph: bodyRow
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 proportionalHeight: 1.0)! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
buildGesturePanel

	"Right-hand column: header row (caption + refresh), the scrollable
	gesture list and a hint label with the 'Ausführen' button."

	| column headerRow hintRow executeRow spacer |
	column := LayoutMorph newColumn separation: 4.
	headerRow := LayoutMorph newRow separation: 4.
	headerRow
		addMorph: (LabelMorph contents: 'Gesten')
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class sliderHeight).
	headerRow
		addMorph:
			(PluggableButtonMorph model: self action: #refreshGestures label: 'Aktualisieren')
		layoutSpec: (LayoutSpec fixedWidth: 140 fixedHeight: self class sliderHeight).
	column
		addMorph: headerRow
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class buttonRowHeight).
	gestureList := PluggableListMorph
		withModel: self
		listGetter: #gestureNames
		indexGetter: #gestureListIndex
		indexSetter: #gestureListIndex:.
	column
		addMorph: gestureList
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 proportionalHeight: 1.0).
	hintRow := LayoutMorph newRow separation: 4.
	hintRow
		addMorph: gestureHint
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class bottomRowHeight).
	column
		addMorph: hintRow
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class bottomRowHeight).
	executeRow := LayoutMorph newRow separation: 4.
	spacer := LayoutMorph newRow.
	executeRow
		addMorph: spacer
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class sliderHeight).
	executeRow
		addMorph:
			(PluggableButtonMorph model: self action: #executeSelectedGesture label: 'Ausführen')
		layoutSpec: (LayoutSpec fixedWidth: 110 fixedHeight: self class sliderHeight).
	column
		addMorph: executeRow
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class buttonRowHeight).
	^column! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestureNames

	"Model accessor for the gesture PluggableListMorph."

	^gestures! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestures

	^gestures! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestureList

	^gestureList! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestureHint

	^gestureHint! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestureListIndex

	^gestureListIndex! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
gestureListIndex: anInteger

	gestureListIndex := anInteger! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
refreshGestures

	"Load the available gesture names asynchronously. The result (or the
	error) is applied to the UI process via UISupervisor."

	gestureHint contents: 'Gesten werden geladen ...'.
	robot
		gestureNamesOnDone: [ :names |
			UISupervisor whenUIinSafeState: [ self setGestureNames: names ] ]
		onError: [ :ex |
			UISupervisor whenUIinSafeState: [ self setGestureNamesError: ex ] ]! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
setGestureNames: namesCollection

	gestures := namesCollection asOrderedCollection.
	gestureListIndex := 0.
	gestureList updateList.
	gestureHint contents:
		gestures size printString, ' Gesten geladen - wähle eine und drücke Ausführen.'! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
setGestureNamesError: anException

	gestureHint contents: 'Gesten-Fehler: ', anException messageText! !

!InmoovServoDemoWindow methodsFor: 'gestures' stamp: 'sf 29/Aug/2026'!
executeSelectedGesture

	| index name |
	index := gestureListIndex ifNil: [ 0 ].
	(index between: 1 and: gestures size)
		ifFalse: [ gestureHint contents: 'Keine Geste ausgewählt.' ]
		ifTrue: [
			name := gestures at: index.
			robot performGesture: name, '()'.
			gestureHint contents: 'Spiele Geste: ', name ]! !

!InmoovServoDemoWindow methodsFor: 'gui-building' stamp: 'sf 24/Aug/2026'!
labelForGroup: aGroupSymbol

	aGroupSymbol = #leftArm ifTrue: [ ^'L-Arm' ].
	aGroupSymbol = #rightArm ifTrue: [ ^'R-Arm' ].
	aGroupSymbol = #leftHand ifTrue: [ ^'L-Hand' ].
	aGroupSymbol = #rightHand ifTrue: [ ^'R-Hand' ].
	aGroupSymbol = #head ifTrue: [ ^'Kopf' ].
	aGroupSymbol = #torso ifTrue: [ ^'Torso' ].
	^aGroupSymbol asString! !

!InmoovServoDemoWindow methodsFor: 'group-selection' stamp: 'sf 24/Aug/2026'!
selectLeftArm

	self selectGroupNamed: #leftArm! !
!InmoovServoDemoWindow methodsFor: 'group-selection' stamp: 'sf 24/Aug/2026'!
selectRightArm

	self selectGroupNamed: #rightArm! !
!InmoovServoDemoWindow methodsFor: 'group-selection' stamp: 'sf 24/Aug/2026'!
selectLeftHand

	self selectGroupNamed: #leftHand! !
!InmoovServoDemoWindow methodsFor: 'group-selection' stamp: 'sf 24/Aug/2026'!
selectRightHand

	self selectGroupNamed: #rightHand! !
!InmoovServoDemoWindow methodsFor: 'group-selection' stamp: 'sf 24/Aug/2026'!
selectHead

	self selectGroupNamed: #head! !
!InmoovServoDemoWindow methodsFor: 'group-selection' stamp: 'sf 24/Aug/2026'!
selectTorso

	self selectGroupNamed: #torso! !

!InmoovServoDemoWindow methodsFor: 'group-selection' stamp: 'sf 24/Aug/2026'!
selectGroupNamed: groupSymbol

	currentGroup := robot perform: groupSymbol.
	lastSent := Dictionary new.
	self rebuildRows.
	self pollOnce! !

!InmoovServoDemoWindow methodsFor: 'gui-building' stamp: 'sf 24/Aug/2026'!
rebuildRows

	| names |
	rowsPane removeAllMorphs.
	names := InmoovServoGroup servoNamesFor: currentGroup kind.
	names do: [ :each |
		rowsPane addMorphBack: (self sliderRowForServoNamed: each) ].
	self adjustExtentForRows! !

!InmoovServoDemoWindow methodsFor: 'gui-building' stamp: 'sf 26/Aug/2026'!
adjustExtentForRows

	"Grow/shrink the window so all slider rows are visible while the
	width stays constant (see minimumExtent). Height comes from the
	layout's own minimum, so no fixed chrome constants are needed."

	| desired |
	desired := self minimumExtent min: (UISupervisor ui viewBox extent - (0@20)).
	self morphExtent: desired.
	self refreshLayout! !

!InmoovServoDemoWindow methodsFor: 'layout' stamp: 'sf 26/Aug/2026'!
minimumExtent

	"Constant width, natural height. Without the width override the
	wrapped status text and the slider rows would force the window to
	grow horizontally with every poll update or knob position."

	^self class preferredWidth @ (super minimumExtent y)! !

!InmoovServoDemoWindow methodsFor: 'layout' stamp: 'sf 29/Aug/2026'!
refreshLayout

	"Force the nested layout computation. The window body is a row of two
	columns (servo controls / gesture panel). In headless images the world
	runs no layout maintenance, so without an explicit recursive cascade
	the rows and lists stay at their natural width after an extent change."

	self validateLayoutFrom: self layoutMorph! !

!InmoovServoDemoWindow methodsFor: 'layout' stamp: 'sf 29/Aug/2026'!
validateLayoutFrom: aMorph

	"Recursively ask every layout node in the tree to place its children.
	Plain widgets (buttons, labels, sliders) have no nested layout."

	(aMorph respondsTo: #layoutSubmorphs) ifTrue: [ aMorph layoutSubmorphs ].
	aMorph submorphs do: [ :each | self validateLayoutFrom: each ]! !

!InmoovServoDemoWindow methodsFor: 'gui-building' stamp: 'sf 24/Aug/2026'!
sliderRowForServoNamed: nameSymbol

	| servo readout slider row |
	servo := currentGroup servoNamed: nameSymbol.
	readout := LabelMorph contents: '--'.
	slider := InmoovSliderMorph new.
	slider labelText: nameSymbol asString.
	servo minValue ifNotNil: [ :m | slider minValue: m ].
	servo maxValue ifNotNil: [ :m | slider maxValue: m ].
	servo restValue ifNotNil: [ :m | slider initialValue: m ].
	slider whenValueChangedDo: [ :v |
		readout contents: v rounded printString.
		self throttledSend: v forServoNamed: nameSymbol ].
	slider whenInteractionEndsDo: [ :v |
		self sendNow: v forServoNamed: nameSymbol ].
	row := LayoutMorph newRow separation: 8.
	row
		addMorph: readout
		layoutSpec: (LayoutSpec fixedWidth: 44 fixedHeight: self class sliderHeight).
	row
		addMorph: slider
		layoutSpec: (LayoutSpec proportionalWidth: 1.0 fixedHeight: self class sliderHeight).
	row layoutSpec: (LayoutSpec
			proportionalWidth: 1.0
			fixedHeight: self class sliderRowHeight).
	^row! !

!InmoovServoDemoWindow methodsFor: 'commands' stamp: 'sf 24/Aug/2026'!
throttledSend: aValue forServoNamed: nameSymbol

	| now |
	now := Time millisecondClockValue.
	(now - (lastSent at: nameSymbol ifAbsent: [ SmallInteger minVal ])) abs < 120
		ifTrue: [ ^self ].
	self sendNow: aValue forServoNamed: nameSymbol! !

!InmoovServoDemoWindow methodsFor: 'commands' stamp: 'sf 24/Aug/2026'!
sendNow: aValue forServoNamed: nameSymbol

	lastSent at: nameSymbol put: Time millisecondClockValue.
	(currentGroup servoNamed: nameSymbol) moveTo: aValue! !

!InmoovServoDemoWindow methodsFor: 'commands' stamp: 'sf 24/Aug/2026'!
restCurrentGroup

	currentGroup ifNotNil: [ currentGroup rest ]! !

!InmoovServoDemoWindow methodsFor: 'commands' stamp: 'sf 24/Aug/2026'!
restAll

	robot restAll! !

!InmoovServoDemoWindow methodsFor: 'polling' stamp: 'sf 24/Aug/2026'!
startPolling

	pollProcess := [
		[
			(Delay forMilliseconds: 700) wait.
			self pollOnce
		] repeat
	] forkAt: Processor userBackgroundPriority named: 'InMoov demo poll'! !

!InmoovServoDemoWindow methodsFor: 'polling' stamp: 'sf 24/Aug/2026'!
pollOnce

	"Runs in the polling process; reads positions synchronously and
	defers the UI update to the UI process."

	| snapshot |
	currentGroup ifNil: [ ^self ].
	snapshot := Dictionary new.
	(InmoovServoGroup servoNamesFor: currentGroup kind) do: [ :each |
		[ snapshot at: each put: (currentGroup servoNamed: each) position ]
			on: Error do: [ :ex | "servo missing - skip" ] ].
	UISupervisor whenUIinSafeState: [ self showSnapshot: snapshot ]! !

!InmoovServoDemoWindow methodsFor: 'updating' stamp: 'sf 24/Aug/2026'!
showSnapshot: snapshotDictionary

	| text |
	text := String streamContents: [ :strm |
		strm nextPutAll: currentGroup groupName asString.
		strm nextPutAll: '   '.
		snapshotDictionary keysSortedSafely do: [ :each |
			strm
				nextPutAll: each asString;
				nextPutAll: '=';
				nextPutAll: ((snapshotDictionary at: each)
					ifNil: [ '--' ]
					ifNotNil: [ :p | p rounded printString ]);
				nextPutAll: '  ' ] ].
	statusLabel contents: text! !

!InmoovServoDemoWindow methodsFor: 'events' stamp: 'sf 24/Aug/2026'!
delete

	pollProcess ifNotNil: [ pollProcess terminate ].
	pollProcess := nil.
	super delete! !


"Postscript:

Open with: InmoovServoDemoWindow openOn: (InmoovRobot host:'localhost' port:8888 robotName:'i01')
Requires a running MRL with started peer groups (virtual mode ok).
"!
