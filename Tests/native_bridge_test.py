import json, pathlib, struct, subprocess, time, tempfile, os
root=pathlib.Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='bridge-test-',dir=root/'runtime') as tmp:
    settings=pathlib.Path(tmp)/'settings.json'
    settings.write_text(json.dumps({'enabled':True,'time':time.time(),'ignored':[]}))
    env=dict(os.environ,NAILONG_TEST_RUNTIME=tmp)
    proc=subprocess.Popen([str(root/'native-host.sh')],stdin=subprocess.PIPE,stdout=subprocess.PIPE,env=env)
    try:
        def call(message):
            data=json.dumps(message).encode();proc.stdin.write(struct.pack('<I',len(data))+data);proc.stdin.flush()
            header=proc.stdout.read(4);assert len(header)==4,'Native host closed unexpectedly'
            return json.loads(proc.stdout.read(struct.unpack('<I',header)[0]))
        assert call({'id':0,'type':'ping'})['running']
        reply=call({'id':1,'type':'check','text':'A beautifull day. ','caret':17})
        assert reply['id']==1 and reply['range']=={'location':2,'length':10},reply
        assert call({'id':2,'type':'check','text':'A beautiful day. ','caret':16})['range'] is None
        assert not call({'id':3,'type':'check','text':'x','caret':100})['ok']
        assert not call({'id':4,'type':'execute','command':'anything'})['ok']
        settings.write_text(json.dumps({'enabled':False,'time':time.time(),'ignored':[]}))
        assert not call({'id':5,'type':'check','text':'beautifull ','caret':11})['ok']
        reply=call({'id':6,'type':'ping'});assert reply['ok'] and not reply['enabled']
        print('PASS: real native framing, ping diagnostics, spelling, correction, invalid ranges, rejected commands, pause gate; runtime isolated.')
    finally:
        proc.stdin.close();proc.wait(timeout=5)
