// 工具函数
function parseParamSize(modelName) {
    var match = modelName.match(/:(\d+[bB])/);
    if (match) {
        return match[1].toUpperCase();
    }
    return "-";
}

function formatFileSize(sizeStr) {
    if (!sizeStr || sizeStr === "-") {
        return "-";
    }

    var size = parseFloat(sizeStr);
    if (isNaN(size)) {
        return sizeStr;
    }

    if (size >= 1073741824) {
        return (size / 1073741824).toFixed(2) + "G";
    } else if (size >= 1048576) {
        return (size / 1048576).toFixed(2) + "M";
    } else if (size >= 1024) {
        return (size / 1024).toFixed(2) + "K";
    } else {
        return size + "B";
    }
}

function parseModelFamily(modelName) {
    var parts = modelName.split("/");
    if (parts.length > 1) {
        var namePart = parts[1].split(":")[0];
        var familyMatch = namePart.match(/^[^-]+/);
        if (familyMatch) {
            return familyMatch[0];
        }
    }
    return "-";
}

function parseQuantization(modelName) {
    // 匹配常见的量化格式
    var quantPatterns = [
        // 匹配 q3_K, q3_K_M, q4_0, q8_0 等格式
        /-(q[0-9]+(_[A-Z]+)+)/,
        /-(q[0-9]+_\d)/,
        // 匹配 fp16, fp32 等格式
        /-(fp[0-9]+)/,
        // 匹配 :q3_K, :q8_0 等格式
        /:(q[0-9]+(_[A-Z]+)+)/,
        /:(q[0-9]+_\d)/,
        /:(fp[0-9]+)/
    ];

    // 遍历所有模式
    for (var i = 0; i < quantPatterns.length; i++) {
        var match = modelName.match(quantPatterns[i]);
        if (match && match[1]) {
            return match[1];
        }
    }

    // 检查tag中的量化格式
    var simpleMatch = modelName.match(/:(.*?)(-|$)/);
    if (simpleMatch) {
        var tag = simpleMatch[1];
        if (tag.match(/q[0-9]+(_[A-Z]+)+/) || tag.match(/q[0-9]+_\d/) || tag.match(/fp[0-9]+/)) {
            return tag;
        }
    }

    return "-";
}