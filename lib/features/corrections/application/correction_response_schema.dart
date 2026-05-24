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
          'corrected_phrase',
          'category',
          'short_explanation',
        ],
        'properties': {
          'start_index': {
            'type': 'integer',
            'description':
                'Zero-based inclusive start index in user-perceived characters.',
          },
          'end_index': {
            'type': 'integer',
            'description':
                'Zero-based exclusive end index in user-perceived characters.',
          },
          'corrected_phrase': {
            'type': 'string',
            'description': 'The replacement phrase for the indexed text range.',
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
  'Indexes are measured in user-perceived characters, not bytes.',
  'The app derives the original phrase from the submitted text range.',
  'Correction items must not include an original_phrase field.',
];
