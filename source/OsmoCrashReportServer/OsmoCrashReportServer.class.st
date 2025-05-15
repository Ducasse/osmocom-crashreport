"
I receive a fuel crash report, provide a quick analysis, store it and notify others
"
Class {
	#name : 'OsmoCrashReportServer',
	#superclass : 'Object',
	#instVars : [
		'server',
		'emailFrom',
		'emailTo',
		'crashDumpDirectory',
		'baseDir'
	],
	#category : 'OsmoCrashReportServer',
	#package : 'OsmoCrashReportServer'
}

{ #category : 'adding' }
OsmoCrashReportServer >> addEmailTo: aTo [ 
	emailTo add: aTo
]

{ #category : 'accessing' }
OsmoCrashReportServer >> crashDumpDirectory: aDirectory [ 
	crashDumpDirectory := aDirectory
]

{ #category : 'operations' }
OsmoCrashReportServer >> createTicketForCrash: aFLHeader data: aCollection [ 
	"TODO.. create jira bug reports"
]

{ #category : 'operations' }
OsmoCrashReportServer >> emailCrash: aHeader data: aDump [ 
	| mail smtp |
	mail := MailMessage
		from: emailFrom
		to: emailTo
		about: 'Received crash report'
		asFollows: (aHeader additionalObjectAt: #backtrace) asString.

	mail addAttachmentFrom: aDump readStream withName: 'crash.fuel'.
	smtp := SMTPClient openOnHostNamed: 'mail.sysmocom.de'.
	[[
		smtp initiateSession.
		smtp mailFrom: mail from to: mail recipientList text: mail text.
		smtp quit
	] on: Error do: [:e | "ignore all mail errors.." ]
	] ensure: [smtp close].
]

{ #category : 'accessing' }
OsmoCrashReportServer >> emailFrom: aFromAddress [ 
	emailFrom := aFromAddress
]

{ #category : 'operations' }
OsmoCrashReportServer >> handleCrash: aRequest response: aResponse [
	| data info |

	aRequest method = 'PUT' ifFalse: [
		^aResponse entity: (ZnStringEntity html: '<h1>Use put</h1>')
	].

	aRequest entity contentType name = 'application/octet-stream' ifFalse: [ 
		^aResponse entity: (ZnStringEntity html: '<h1>Use application/octet-stream</h1>')
	 ].

	data := aRequest entity bytes.
	info := FLMaterializer newDefault materializeHeaderFrom: data readStream.
	self storeCrash: info data: data.
	self emailCrash: info data: data.
	self createTicketForCrash: info data: data.
	^aResponse entity: (ZnStringEntity html: '<h1>Too bad it crashed</h1>')
]

{ #category : 'initialization' }
OsmoCrashReportServer >> initialize [
	super initialize.
	emailTo := OrderedCollection new.
	baseDir := FileSystem workingDirectory.
	server := ZnServer defaultServerClass new.
	server delegate: (ZnDispatcherDelegate new 
			map: '/crash' to: [ :request :response | self handleCrash: request response: response ]).
]

{ #category : 'operations' }
OsmoCrashReportServer >> start: aPort [
	server port: aPort.
	server start.
]

{ #category : 'operations' }
OsmoCrashReportServer >> storeCrash: aHeader data: aDump [ 
	| fileName |
	fileName := crashDumpDirectory / 'crash-', DateAndTime now asUnixTime printString, '.fuel'.
	fileName asFileReference writeStreamDo: [:stream |
		stream nextPutAll: aDump.
	]
]
