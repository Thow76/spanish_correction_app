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
          'corrected_start_index',
          'corrected_end_index',
          'original_phrase',
          'corrected_phrase',
          'category',
          'short_explanation',
        ],
        'properties': {
          'start_index': {
            'type': 'integer',
            'description':
                'Zero-based inclusive start index in user-perceived characters, marking where original_phrase begins in the submitted text. For insertions, this is the insertion point.',
          },
          'corrected_start_index': {
            'type': 'integer',
            'description':
                'Zero-based inclusive index of corrected_phrase in the corrected_text string you return, in user-perceived characters. For deletions, this must equal corrected_end_index.',
          },
          'corrected_end_index': {
            'type': 'integer',
            'description':
                'Zero-based exclusive index of corrected_phrase in the corrected_text string you return, in user-perceived characters. The slice of corrected_text between corrected_start_index and corrected_end_index must equal corrected_phrase exactly.',
          },
          'original_phrase': {
            'type': 'string',
            'description':
                'The exact substring of the submitted text starting at start_index. Empty string for an inserted phrase. Must match the text at that position exactly so the app can verify the index.',
          },
          'corrected_phrase': {
            'type': 'string',
            'description':
                'The replacement phrase for original_phrase, or inserted text when original_phrase is empty.',
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
      "corrected_start_index": 0,
      "corrected_end_index": 0,
      "original_phrase": "string",
      "corrected_phrase": "string",
      "category": "string",
      "short_explanation": "string"
    }
  ]
}
''';

const correctionResponseIndexingRules = [
  'start_index is zero-based and inclusive, marking where original_phrase begins in the submitted text.',
  'For an inserted phrase, start_index is the insertion point and original_phrase is empty.',
  'Indexes are measured in user-perceived characters, not bytes.',
  'original_phrase must equal the exact substring of the submitted text starting at start_index, character-for-character.',
  'For an inserted phrase, original_phrase must be an empty string.',
  'The app rejects any correction whose original_phrase does not match the text at start_index, so use this field to verify your own index before responding.',
];
