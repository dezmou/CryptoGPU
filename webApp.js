const TIME_TEST_ALIVE = 150;

const getStream = (call) => {
    return new Promise((resolve) => {
        let ws = new WebSocket("ws://127.0.0.1:5555");
        ws.onmessage = function (event) {
            call(event.data);
        };
        ws.onerror = resolve;
        ws.onclose = resolve;
    });
}

const getLastTime = () => {
    return new Promise((resolve) => {
        $.get( "time", function( data ) {
            resolve(data);
        });
    });
}

const sleep = (millis) => {
    return new Promise((resolve) => {
        setTimeout(resolve,millis)
    });
}

const connectServer = async (call) => {
    let lastTime = getLastTime();
    while (true){
        await getStream(call);
        while (true){
            let actTime = await getLastTime();
            if (actTime !== lastTime){
                lastTime = actTime;
                break;
            }
            await sleep(TIME_TEST_ALIVE);
        }
    }
}