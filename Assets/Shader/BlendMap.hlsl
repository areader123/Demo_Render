#ifndef BLENDMAP_INCLUDE
    #define BLENDMAP_INCLUDE
    float HeigthLerp(float Height,float Transition,float BlendContrast)
    {
        return clamp(lerp(-BlendContrast,1+BlendContrast,clamp((Height - 1) + (Transition * 2),0,1)),0,1);
    }
    //BlendContrast的范围为0，0.1
    half3 BlendWeightWithHeight(half4 colorVertex,half BlendContrast,half Height_Fir,half Height_Sec,half Height_Thi)
    {
        half maxChannel = max(max(colorVertex.r + Height_Fir ,colorVertex.g + Height_Sec),colorVertex.b + Height_Thi);
        half delt =  maxChannel - BlendContrast;
        half Rdelt = colorVertex.r + Height_Fir - delt;
        half Bdelt = colorVertex.b + Height_Thi- delt;
        half Gdelt = colorVertex.g + Height_Sec- delt;

        Rdelt = max(0,Rdelt);
        Bdelt = max(0,Bdelt);
        Gdelt = max(0,Gdelt);

        return half3(Rdelt,Bdelt,Gdelt)/(Rdelt+Bdelt+Gdelt);
    }

#endif