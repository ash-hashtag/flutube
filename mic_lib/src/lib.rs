use cpal::{
    traits::{DeviceTrait, HostTrait, StreamTrait},
    Device, Host, Stream,
};

// fn main() {
//     let host = cpal::host_from_id(cpal::HostId::Wasapi).unwrap();

//     let device = host.default_input_device().unwrap();

//     let config = device.default_input_config().unwrap();

//     let threshold = std::env::args()
//         .skip(1)
//         .next()
//         .and_then(|x| x.parse::<f32>().ok())
//         .unwrap_or(0f32);

//     print!(
//         "Device name: {}, threshold: {}\n",
//         device.name().unwrap(),
//         threshold
//     );
//     let stream = device
//         .build_input_stream(
//             &config.into(),
//             move |data, _: &_| print_threshold(data, threshold),
//             |err| eprintln!("error: {err}"),
//             None,
//         )
//         .unwrap();

//     stream.play().unwrap();

//     std::thread::sleep(std::time::Duration::from_secs(std::u64::MAX));
//     drop(stream);
// }

// fn print_threshold(slice: &[f32], threshold: f32) {
//     for i in slice {
//         if *i > threshold {
//             print!("{i}\n");
//         }
//     }
// }

pub struct MicLib {
    host: Host,
    selected_input_device: Device,
    stream: Option<Stream>,
}

impl MicLib {
    pub fn new() -> Option<Self> {
        let host = cpal::default_host();
        let selected_input_device = host.default_input_device()?;
        let stream = None;
        Some(Self {
            host,
            selected_input_device,
            stream,
        })
    }

    pub fn get_devices(&self, ptr: *mut u8, len: usize) -> isize {
        let mut filled = 0;
        let slice = unsafe { std::slice::from_raw_parts_mut(ptr, len) };
        if let Ok(devices) = self.host.input_devices() {
            for device in devices {
                if let Ok(name) = device.name() {
                    let bytes = name.as_bytes();
                    if filled + bytes.len() < slice.len() {
                        slice[filled..filled + bytes.len()].copy_from_slice(bytes);
                        filled = filled + bytes.len() + 1;
                        slice[filled - 1] = '|' as u8;
                    } else {
                        break;
                    }
                }
            }
        } else {
            return -1;
        }
        filled as isize
    }

    pub fn select_input_device(&mut self, device_name: &str) -> Option<()> {
        if self.stream.is_none() {
            for device in self.host.input_devices().ok()? {
                if let Ok(name) = device.name() {
                    if name == device_name {
                        self.selected_input_device = device;
                        return Some(());
                    }
                }
            }
        }
        None
    }
    pub fn get_sample_format(&self) -> isize {
        if let Ok(config) = self.selected_input_device.default_input_config() {
            return match config.sample_format() {
                cpal::SampleFormat::I8 => 0,
                cpal::SampleFormat::I16 => 1,
                cpal::SampleFormat::I32 => 2,
                cpal::SampleFormat::I64 => 3,
                cpal::SampleFormat::U8 => 4,
                cpal::SampleFormat::U16 => 5,
                cpal::SampleFormat::U32 => 6,
                cpal::SampleFormat::U64 => 7,
                cpal::SampleFormat::F32 => 8,
                cpal::SampleFormat::F64 => 9,
                _ => -1,
            };
        } else {
            return -1;
        }
    }
    pub fn start_listening(
        &mut self,
        f: extern "C" fn(*const f32, usize),
        err_fn: extern "C" fn(),
    ) -> Option<()> {
        if self.stream.is_none() {
            let config = self.selected_input_device.default_input_config().ok()?;
            let stream = self
                .selected_input_device
                .build_input_stream(
                    &config.into(),
                    move |data: &[f32], _| {
                        let ptr = data.as_ptr();
                        f(ptr, data.len());
                    },
                    move |err| {
                        eprintln!("error on stream: {err}");
                        err_fn();
                    },
                    None,
                )
                .ok()?;
            self.stream = Some(stream);
        }
        Some(())
    }
    pub fn stop_listening(&mut self) {
        if let Some(stream) = self.stream.take() {
            drop(stream);
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn get_devices(ptr: *const MicLib, optr: *mut u8, len: usize) -> isize {
    (*ptr).get_devices(optr, len)
}

#[no_mangle]
pub unsafe extern "C" fn set_device(ptr: *mut MicLib, dptr: *const u8, len: usize) -> isize {
    let slice = std::slice::from_raw_parts(dptr, len);
    if let Ok(device_name) = std::str::from_utf8(slice) {
        if (*ptr).select_input_device(device_name).is_some() {
            return 0;
        } else {
            return -1;
        }
    } else {
        return -2;
    }
}

#[no_mangle]
pub unsafe extern "C" fn get_sample_format(ptr: *const MicLib) -> isize {
    (*ptr).get_sample_format()
}

#[no_mangle]
pub extern "C" fn instantiate_mic_lib() -> *mut MicLib {
    let mic_lib = Box::new(MicLib::new().unwrap());
    let ptr = Box::into_raw(mic_lib);
    ptr
}

#[no_mangle]
pub unsafe extern "C" fn free_mic_lib(ptr: *mut MicLib) {
    (*ptr).stop_listening();
    drop(Box::from_raw(ptr));
}

#[no_mangle]
pub unsafe extern "C" fn hello(ptr: *const u8, len: usize, optr: *mut u8) -> isize {
    let hello_bytes = "Hello ".as_bytes();
    let value = std::slice::from_raw_parts(ptr, len);
    let oslice = std::slice::from_raw_parts_mut(optr, 64);

    oslice[0..hello_bytes.len()].copy_from_slice(hello_bytes);
    oslice[hello_bytes.len()..hello_bytes.len() + len].copy_from_slice(value);

    return (hello_bytes.len() + len) as isize;
}

#[no_mangle]
pub unsafe extern "C" fn selected_device(ptr: *const MicLib, optr: *mut u8, len: usize) -> isize {
    if let Ok(name) = (*ptr).selected_input_device.name() {
        let bytes = name.into_bytes();
        if bytes.len() <= len {
            let slice = std::slice::from_raw_parts_mut(optr, bytes.len());
            slice.copy_from_slice(&bytes);
            return bytes.len() as isize;
        } else {
            return -1;
        }
    } else {
        return -2;
    }
}

#[no_mangle]
pub unsafe extern "C" fn start_listening(
    ptr: *mut MicLib,
    f: extern "C" fn(*const f32, usize),
    err_fn: extern "C" fn(),
) -> isize {
    if (*ptr).start_listening(f, err_fn).is_some() {
        0
    } else {
        -1
    }
}

#[no_mangle]
pub unsafe extern "C" fn stop_listening(ptr: *mut MicLib) {
    (*ptr).stop_listening();
}
