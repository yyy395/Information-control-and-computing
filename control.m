function control=control(x)
    x=string(x);
    switch x
        case 'go'
            control='小车前进';
        case 'right'
            control='小车右转';
        case 'up'
            control='小车抬起前轮';
        case 'left'
            control='小车左转';
        case 'down'
            control='小车放下前轮';
        case 'stop'
            control='小车停止';
        case 'unknown'
            control='The command is unknown.';
        case 'background'
            control='The command is background noise.';
        case 'on'
            control='The command is not right';
        case 'off'
            control='The command is not right';
        case 'yes'
            control='The command is not right';
        case 'no'
            control='The command is not right';
    end
end