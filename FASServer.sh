#!/bin/bash
#rm nohupServer.out; nohup ~/32bit_q/l32/q FASServer32bitInit.q > nohupServer.out & tail -f nohupServer.out # 32bit server
rm nohupServer.out; nohup q FASServer64bitInit.q -U credentials.txt > nohupServer.out & tail -f nohupServer.out