"""Service contract tests; no shared DB, credentials or external requests."""
import asyncio
import unittest
from unittest.mock import patch
from app.services.speech_service import SpeechService, TTSError, ASRError

class Response:
    def __init__(self, body=b'audio', data=None, status=200, content_type='audio/mpeg', error=None):
        self.body, self.data, self.status, self.error = body, data, status, error
        self.headers = {'Content-Type': content_type}
    async def __aenter__(self):
        if self.error: raise self.error
        return self
    async def __aexit__(self, *args): pass
    async def read(self): return self.body
    async def json(self): return self.data

class Session:
    def __init__(self, responses): self.responses = iter(responses); self.calls=[]
    async def __aenter__(self): return self
    async def __aexit__(self, *args): pass
    def post(self, url, **kwargs):
        self.calls.append((url, kwargs))
        return next(self.responses)

class SpeechContract(unittest.IsolatedAsyncioTestCase):
    async def test_valid_tts_preserves_complete_input(self):
        session=Session([Response()]); text='完整长段落\n'*100
        with patch('app.services.speech_service.aiohttp.ClientSession', return_value=session):
            result=await SpeechService(api_key='test').text_to_speech(text)
        self.assertEqual(result.input_text,text)
        self.assertEqual(session.calls[0][1]['json']['input'],text)
    async def test_empty_and_non_audio_success_rejected(self):
        for response in [Response(body=b''),Response(body=b'{"error":"secret"}',content_type='application/json')]:
            with self.subTest(response=response),patch('app.services.speech_service.aiohttp.ClientSession',return_value=Session([response])):
                with self.assertRaises(TTSError): await SpeechService(api_key='test').text_to_speech('正文')
    async def test_tts_invalid_input_never_requests_provider(self):
        with patch('app.services.speech_service.aiohttp.ClientSession') as session:
            for kwargs in [dict(text=' '),dict(text='正文',speed=float('nan')),dict(text='正文',speed=True),dict(text='正文',response_format='json')]:
                with self.subTest(kwargs=kwargs),self.assertRaises(TTSError):
                    await SpeechService(api_key='test').text_to_speech(**kwargs)
            session.assert_not_called()
    async def test_tts_timeout_is_domain_error(self):
        with patch('app.services.speech_service.aiohttp.ClientSession',return_value=Session([Response(error=asyncio.TimeoutError())])):
            with self.assertRaisesRegex(TTSError,'超时'): await SpeechService(api_key='test').text_to_speech('正文')
    async def test_asr_timeout_is_domain_error(self):
        with patch('app.services.speech_service.aiohttp.ClientSession',return_value=Session([Response(error=asyncio.TimeoutError())])):
            with self.assertRaisesRegex(ASRError,'超时'): await SpeechService(api_key='test').speech_to_text(b'recording')
    async def test_empty_asr_fallback_also_empty_is_failure(self):
        session=Session([Response(data={'text':' '}),Response(data={'text':''})])
        with patch('app.services.speech_service.aiohttp.ClientSession',return_value=session):
            with self.assertRaisesRegex(ASRError,'未识别'): await SpeechService(api_key='test').speech_to_text(b'recording')
        self.assertEqual(len(session.calls),2)
    async def test_valid_asr_fallback_retains_text(self):
        session=Session([Response(data={'text':''}),Response(data={'text':'完整识别\n第二行'})])
        with patch('app.services.speech_service.aiohttp.ClientSession',return_value=session):
            result=await SpeechService(api_key='test').speech_to_text(b'recording')
        self.assertEqual(result.text,'完整识别\n第二行')
    async def test_invalid_asr_types_rejected(self):
        for data in [{'text':5}, {'text':None}, [], {}]:
            with self.subTest(data=data),patch('app.services.speech_service.aiohttp.ClientSession',return_value=Session([Response(data=data)])):
                with self.assertRaises(ASRError): await SpeechService(api_key='test').speech_to_text(b'recording')
    async def test_empty_recording_never_requests_provider(self):
        with patch('app.services.speech_service.aiohttp.ClientSession') as session:
            with self.assertRaises(ASRError): await SpeechService(api_key='test').speech_to_text(b'')
            session.assert_not_called()
    async def test_http_errors_do_not_become_typeerror(self):
        for method,error,args in [('text_to_speech',TTSError,('正文',)),('speech_to_text',ASRError,(b'recording',))]:
            with patch('app.services.speech_service.aiohttp.ClientSession',return_value=Session([Response(status=503)])):
                with self.assertRaisesRegex(error,'503'): await getattr(SpeechService(api_key='test'),method)(*args)

if __name__=='__main__': unittest.main()
