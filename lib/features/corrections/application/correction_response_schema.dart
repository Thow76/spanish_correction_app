const correctionResponseJsonSchema = <String, Object?>{
  'type': 'object',
  'additionalProperties': false,
  'required': ['original_text', 'corrected_text', 'corrections'],
  'properties': {
    'original_text': {
      'type': 'string',
      'description': 'The submitted text copied exactly as received.',
    },
    'corrected_text': {
      'type': 'string',
      'description': 'A polished corrected version of the whole text.',
    },
    'corrections': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'start_index',
          'end_index',
          'original_phrase',
          'corrected_phrase',
          'category',
          'short_explanation',
        ],
        'properties': {
          'start_index': {
            'type': 'integer',
            'description':
                'Zero-based inclusive start index in user-perceived characters. For insertions, this is the insertion point.',
          },
          'end_index': {
            'type': 'integer',
            'description':
                'Zero-based exclusive end index in user-perceived characters. For insertions, this must equal start_index.',
          },
          'original_phrase': {
            'type': 'string',
            'description':
                'The exact substring of the submitted text between start_index and end_index. Empty string for zero-length insertion ranges. Must match the indexed slice exactly so the app can verify the range.',
          },
          'corrected_phrase': {
            'type': 'string',
            'description':
                'The replacement phrase for the indexed text range, or inserted text for a zero-length range.',
          },
          'category': {
            'type': 'string',
            'enum': [
              'Grammar',
              'Natural Language',
              'Spelling',
              'Word Choice',
              'Other',
            ],
          },
          'short_explanation': {
            'type': 'string',
            'description':
                'One informal but technically accurate explanation sentence.',
          },
        },
      },
    },
  },
};

const correctionResponseJsonShape = '''
{
  "original_text": "string",
  "corrected_text": "string",
  "corrections": [
    {
      "start_index": 0,
      "end_index": 0,
      "original_phrase": "string",
      "corrected_phrase": "string",
      "category": "string",
      "short_explanation": "string"
    }
  ]
}
''';

const correctionResponseIndexingRules = [
  'start_index is zero-based and inclusive.',
  'end_index is zero-based and exclusive.',
  'For insertions, start_index and end_index are the same cursor position.',
  'Indexes are measured in user-perceived characters, not bytes.',
  'original_phrase must equal the exact substring of the submitted text between start_index and end_index, character-for-character.',
  'For zero-length insertion ranges, original_phrase must be an empty string.',
  'The app rejects any correction whose original_phrase does not match the indexed slice, so use this field to verify your own indexes before responding.',
];
