MAX16 = 0xFFFF

def update(acc, inc):
    total = acc + inc
    sat = total > MAX16
    nxt = MAX16 if sat else total
    return nxt, sat

def run(increments, initial=0):
    acc = initial
    out=[]
    for inc in increments:
        acc, sat = update(acc, inc)
        out.append((acc, acc >> 8, sat))
    return out

def test_no_overflow():
    assert update(100, 20) == (120, False)

def test_exact_boundary():
    assert update(65535, 0) == (65535, False)
    assert update(65534, 1) == (65535, False)

def test_overflow():
    assert update(65535, 1) == (65535, True)
    assert update(65500, 100) == (65535, True)

def test_sticky_saturation():
    acc=65535
    for inc in [1,2,255,65535]:
        acc,sat=update(acc,inc)
        assert acc==65535 and sat

def test_upper_byte():
    assert update(0x1200,0x34)[0] >> 8 == 0x12
    assert update(0x12FF,0)[0] >> 8 == 0x12

def test_randomized():
    import random
    random.seed(4)
    for _ in range(5000):
        acc=random.randint(0,MAX16)
        inc=random.randint(0,MAX16)
        nxt,sat=update(acc,inc)
        assert nxt==min(acc+inc,MAX16)
        assert sat==(acc+inc>MAX16)

if __name__=="__main__":
    test_no_overflow()
    test_exact_boundary()
    test_overflow()
    test_sticky_saturation()
    test_upper_byte()
    test_randomized()
    print("G04 golden reference PASS")
