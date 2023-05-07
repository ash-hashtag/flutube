use std::{
    sync::{Arc, Mutex},
    time::Duration,
};

use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};

fn main() {
    let host = cpal::host_from_id(cpal::HostId::Wasapi).unwrap();

    let device = host.default_input_device().unwrap();

    let config = device.default_input_config().unwrap();

    let threshold = std::env::args()
        .skip(1)
        .next()
        .and_then(|x| x.parse::<f32>().ok())
        .unwrap_or(0f32);

    print!(
        "Device name: {}, threshold: {}\n",
        device.name().unwrap(),
        threshold
    );
    let stream = device
        .build_input_stream(
            &config.into(),
            move |data, _: &_| print_threshold(data, threshold),
            |err| eprintln!("error: {err}"),
            Some(Duration::from_secs(3)),
        )
        .unwrap();

    stream.play().unwrap();

    std::thread::sleep(std::time::Duration::from_secs(100));
    drop(stream);

    // println!("{:?}", buffer_handle.lock().unwrap());
}

fn print_threshold(slice: &[f32], threshold: f32) {
    for i in slice {
        if *i > threshold {
            print!("{i}\n");
        }
    }
}
