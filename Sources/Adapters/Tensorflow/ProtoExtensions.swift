//
//  ProtoExtensions.swift
//  Bender
//
//  Created by Mathias Claassen on 5/19/17.
//
//

import Foundation

extension Tensorflow_NodeDef {

    /// Gets the shape of the node. Works on Const and VariableV2 nodes
    var shape: Tensorflow_TensorShapeProto? {
        return attr["shape"]?.shape ?? attr["value"]?.tensor.tensorShape
    }

    /// Parse strides from a node
    var strides: (x: Int, y: Int)? {
        guard let strides = attr["strides"]?.list.i else {
                return nil
        }

        guard let dataFormat = attr["data_format"]?.s,
            let formatString = String(data: dataFormat, encoding: .utf8) else {
            return (Int(strides[1]), Int(strides[2]))
        }

        let strideX = formatString == "NHWC" ? strides[2] : strides[3]
        let strideY = formatString == "NHWC" ? strides[1] : strides[2]
        return (Int(strideX), Int(strideY))
    }

    /// Parse dilations from a node
    var dilations: (x: Int, y: Int)? {
        guard let dilations = attr["dilations"]?.list.i else {
            return nil
        }

        guard let dataFormat = attr["data_format"]?.s,
            let formatString = String(data: dataFormat, encoding: .utf8) else {
                return (Int(dilations[1]), Int(dilations[2]))
        }

        let dilationX = formatString == "NHWC" ? dilations[2] : dilations[3]
        let dilationY = formatString == "NHWC" ? dilations[1] : dilations[2]
        return (Int(dilationX), Int(dilationY))
    }

    /// Parses a size from a node like in Max and AvgPooling
    var ksize: (width: Int, height: Int)? {
        guard let size = attr["ksize"]?.list.i else {
                return nil
        }

        guard let dataFormat = attr["data_format"]?.s,
            let formatString = String(data: dataFormat, encoding: .utf8) else {
            return (Int(size[1]), Int(size[2]))
        }

        let width = formatString == "NHWC" ? size[2] : size[3]
        let height = formatString == "NHWC" ? size[1] : size[2]
        return (Int(width), Int(height))
    }

    /// This helper searches for a "Neuron" attribute in the node and if it is present it creates an ActivationNeuronType from its information
    func activationNeuron() -> ActivationNeuronType {
        var neuron = ActivationNeuronType.none
        if let neuronOp = attr[Constants.CustomAttr.neuron]?.s, let opString = String(data: neuronOp, encoding: .utf8) {
            switch opString {
            case Constants.Ops.Relu:
                neuron = .relu
            case Constants.Ops.Tanh:
                neuron = .tanh
            case Constants.Ops.Sigmoid:
                neuron = .sigmoid
            default:
                break
            }
        }
        return neuron
    }

    func valueData() -> Data? {
        if isTFConstOp, let data = attr["value"]?.tensor.tensorContent {
            return data
        }
        return nil
    }

    func valueScalar() -> Float? {
        if isTFConstOp, let tensor = attr["value"]?.tensor {
            switch tensor.dtype {
            case .dtFloat:
                return tensor.floatVal.first
            case .dtDouble:
                if let doubleVal = tensor.doubleVal.first {
                    return Float(doubleVal)
                }
                break
            case .dtInt8, .dtInt16, .dtInt32, .dtUint8:
                if let intVal = tensor.intVal.first {
                    return Float(intVal)
                }
                break
            default:
                break
            }
        }
        return nil
    }

}

extension Tensorflow_TensorShapeProto {

    var isBias: Bool {
        return dim.count == 1
    }

    var toShape: Shape {
        return Shape(width: kernelWidth, height: kernelHeight, inputChannels: inputChannels, outputChannels: outputChannels)
    }

    // MARK: Named dimensions (these apply to Conv2D order)
    var kernelHeight: Int {
        return Int(dim[0].size)
    }

    var kernelWidth: Int {
        return Int(dim[1].size)
    }

    var inputChannels: Int {
        return Int(dim[2].size)
    }

    var outputChannels: Int {
        return Int(dim[3].size)
    }

    // MARK: Other helpers
    var totalCount: Int {
        return outputChannels * inputChannels * kernelWidth * kernelHeight
    }

}
