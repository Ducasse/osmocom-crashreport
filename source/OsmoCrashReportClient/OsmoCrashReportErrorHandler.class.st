Class {
	#name : 'OsmoCrashReportErrorHandler',
	#superclass : 'Object',
	#instVars : [
		'reportUrl',
		'username',
		'password'
	],
	#category : 'OsmoCrashReportClient',
	#package : 'OsmoCrashReportClient'
}

{ #category : 'event handling' }
OsmoCrashReportErrorHandler >> handleError: anError on: block [ 
	self reportError: anError
]

{ #category : 'event handling' }
OsmoCrashReportErrorHandler >> handleTimerError: anError on: aTimer [
	self reportError: anError
]

{ #category : 'private' }
OsmoCrashReportErrorHandler >> reportError: anError [ 
	| backTrace serializer data |
	backTrace := anError signalerContext stack collect: [:each | each asString ].

	serializer := FLSerializer newDefault.
	serializer at: #backtrace putAdditionalObject: backTrace.

	"TODO: write stuff about the application"

	serializer addPostMaterializationAction: [ :materialization | 
		Smalltalk tools debugger
			openOn: Processor activeProcess 
			context: materialization root 
			label: 'Unhandled exception' 
			contents: nil 
			fullView: false ].

	data := #[] writeStream.
	serializer serialize: anError signalerContext on: data.

	"Fire and forget..."
	[ 
		ZnEasy client
			url: reportUrl;
			setBasicAuthenticationUsername: username password: password;
			entity: (ZnByteArrayEntity  bytes: data contents);
			ifFail: [:err |
				err logException: 'Failed to upload crash' area: #core];
			put;
			response.
	] fork.
]

{ #category : 'accessing' }
OsmoCrashReportErrorHandler >> reportUrl: aUrl [  
	reportUrl := aUrl
]

{ #category : 'instance creation' }
OsmoCrashReportErrorHandler >> username: aUsername password: aPassword [ 
	username := aUsername.
	password := aPassword.
]
