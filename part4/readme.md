## part 4: give me a challenge

In part 4 you're up to make a serverless solution in AWS, without many constraints. You're only given a problem, some constraints for the solution, and we wish you happy developing!

## The problem

We got a new client! It's a small startup that needs an API for the smart home appliance they're selling. The appliance takes readings from a home and intelligently controls the temperature. One of the features is that movement tracking makes sure the appliance knows where the residents are, so when nobody is at home the temperature is adjusted automatically (heating in winter, airco in summer). One of the complaints from users is that when they only step out for a minute they always come back to a cold house in winter or a hot house in summer. The startup has developed an AI module that predicts when people get home to make sure they come home to a comfortable temperature. The AI module is too large to run in the appliance itself and the information about the movements is required to keep training the model to improve it. They've asked us to develop a REST API to allow the appliance to use this model, this requires only two simple endpoints:

* `/register_movement` - Register some movement, the message body will a JSON message and on success the endpoint should return 201 (any return body will be ignorted). The appliance will handle 4xx and 5xx errors from the endpoint.
* `/predict_return` - Predict when the user will get back home, the endpoint should return 200 with a JSON body. The appliance will handle 4xx and 5xx errors from the endpoint.

**Registration JSON**
``` json
{
    "timestamp": "2020-11-27T10:06:56+01:00",
    "movement": "leave" // or "home" when the user comes back
}
```

**Prediction JSON**
``` json
{
    "left": "2020-11-27T10:06:56+01:00", // last registered moment the user left
    "prediction": "2020-11-27T17:29:12+01:00" // predicted return moment
}
```

Because the AI model is still in development, it's okay to always predict the return time as 1 hour after the user left.

## Solution constraints

* Budget is a serious issue for this project, the client is a small startup and needs to squeeze every drop out of each dollar, so your solution should be as budget friendly as possible.
* Security is important, so make sure you take precautions where you can. One thing that's absolute no go is any form of unencrypted storage of secrets like database credentials.
* All movements must be saved to a database, as well as all predicted return times.
* All appliances will authenticate themselves using a unique, but (for the device) static API key in an `Authorization`. We got no control over these keys, they're hard wired into the appliance. All we know is that all API keys are SHA1 hashes.
