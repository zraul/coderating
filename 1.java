package com.android.smarttouch.core;

import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Color;
import android.net.Uri;
import android.os.Handler;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.widget.RemoteViews;

import com.android.open.Interface.EventHandlerInterface;
import com.android.open.event.StatusEvent;
import com.android.open.event.TaskRunEvent;
import com.android.open.preference.PreferenceUtil;
import com.android.open.util.Constants;
import com.android.open.util.DateFormat;
import com.android.open.util.RootUtil;
import com.android.smarttouch.util.STPopTip;
import com.android.open.util.SignalToolClass;
import com.android.open.util.ThreadUtil;
import com.android.smarttouch.R;
import com.android.smarttouch.ctrl.SmartTouch;
import com.android.smarttouch.home.HomeActivity;
import com.android.smarttouch.net.NetMsgRequestDeviceInfo;

import de.greenrobot.event.EventBus;

/**
 * 
 * 
 * */
public class EventHandler {

	private int mScriptRunCnt = 0;
	private int mMailID = 0;
	private String mMail = null;
	private String mMailPasswd = null;
	private String mAccount = null;
	private String mPassword = null;
	private String mScriptName = null;
	private String mVecode = null;
	private String mVecodeType = null;
	private String mResolution = null;
	private String mDexPath = null;
	private StringBuffer mRandAccount;
	private StringBuffer mRandChar;
	private Service mService;
	private LocalBroadcastManager mLocalBroadcastManager;
	private BroadcastReceiver mBroadcastReceiver;
	private ClipboardManager mClipboard = null;
	private Notification mNotification;
	private int mRunCnt;
	private SmartTouch smarttouch;
	private boolean mIsVPNConnect;
	private boolean mIsErrorStop = false;
	private boolean mIsQuit = false;

	private Handler mHandler = new Handler() {
		public void handleMessage(android.os.Message msg) {
			switch (msg.what) {
			case 1:
				smarttouch.PausePlay();
				break;
			case 2:
				smarttouch.ResumePlay();
				break;
			case 3:
				mService.stopSelf();
				mService.onDestroy();
				onDestroy();
				break;
			case 4:
				Log.e(Constants.TAG, "==========Error=========");
				break;
			case 5:
				String filename = ((Intent) msg.obj).getStringExtra("filename");
				doDeleteFile(filename);
				setupNotification(mService.getString(R.string.current_status)
						+ mService.getString(R.string.status_deletefile));
				break;
			case 6:
				Intent intent = (Intent) msg.obj;
				setInitLoadScript(intent);
				short nStatus = intent.getShortExtra("Status",
						SmartTouch.RS_READY);
				Log.e(Constants.TAG, "scriptLoad:" + mScriptName + " status="
						+ nStatus);
				smarttouch.setPlayScript(mScriptName);
				smarttouch.setCurrentStaus(nStatus);
				smarttouch.setPlayHotKey(SmartTouch.HK_VOL_DOWN);
				smarttouch.setRecordHotKey(SmartTouch.HK_NO_VALUE);
				String tip = String.format(
						mService.getString(R.string.load_play_tip), "音量-");
				STPopTip.getInstance(mService, tip, Color.RED, 3000).execute();
				setLoadScriptDo();

				setupNotification(mService.getString(R.string.current_status)
						+ mService.getString(R.string.status_wait_play));
				break;
			case 7:
				setPlayScriptDo();
				setupNotification(mService.getString(R.string.current_status)
						+ mService.getString(R.string.status_start_play));
				break;
			case 8:
				intent = (Intent) msg.obj;
				long ret = intent.getLongExtra("ret", 200);
				smarttouch.StopPlay();
				setStopScriptDo(ret);
				setupNotification(mService.getString(R.string.current_status)
						+ mService.getString(R.string.status_stop_play));
				break;
			case 9:
				// downloadurl
				intent = (Intent) msg.obj;
				String url = intent.getStringExtra("url");
				doDownloadUrl(url);

				setupNotification(mService.getString(R.string.current_status)
						+ mService.getString(R.string.status_download));
				break;
			case 10:
				// openurl
				intent = (Intent) msg.obj;
				url = intent.getStringExtra("url");
				doOpenUlr(url);
				break;
			case 11:
				// switchvpn and device
				intent = (Intent) msg.obj;
				int action = intent.getIntExtra("action", 3);
				String param = intent.getStringExtra("param");

				setupNotification(mService.getString(R.string.current_status)
						+ mService.getString(R.string.status_switch));

				smarttouch.PausePlay();
				if (action == 1) {
					doSwitchVPN();
				} else if (action == 2) {
					doSwitchDevice(param);
				} else if (action == 3) {
					doSwitchDevice(param);
					doSwitchVPN();
				}
				smarttouch.ResumePlay();
				break;
			case 12:
				mIsErrorStop = true;
				break;
			case 13:
				intent = (Intent) msg.obj;
				String path = intent.getStringExtra("ScriptName");
				String des = intent.getStringExtra("Description");
				nStatus = intent.getShortExtra("Status", SmartTouch.RS_READY);

				smarttouch.setCurrentStaus(nStatus);
				smarttouch.setRecordScript(path);
				smarttouch.setInstruction(des);
				smarttouch.setPlayHotKey(SmartTouch.HK_NO_VALUE);
				smarttouch.setRecordHotKey(SmartTouch.HK_VOL_UP);
				String tipString = String.format(
						mService.getString(R.string.load_record_tip), "音量+");
				STPopTip.getInstance(mService, tipString, Color.RED, 3000)
						.execute();
				break;
			case 14:
				smarttouch.StartRecord();
				setupNotification(mService.getString(R.string.current_status)
						+ mService.getString(R.string.status_start_record));
				break;
			case 15:
				smarttouch.StopRecord();
				setupNotification(mService.getString(R.string.current_status)
						+ mService.getString(R.string.status_stop_record));
				break;
			case 16:
				smarttouch.QuitPlay();
				break;
			case 17:
				intent = (Intent) msg.obj;// Business
				Log.e(Constants.TAG, "======" + intent.getStringExtra("cmd")
						+ "==" + intent.getStringExtra("param") + "====");
				break;
			default:
				break;
			}
		};
	};

	public EventHandler(Service service) {
		mService = service;
		mRunCnt = 0;
		mIsVPNConnect = false;
		Init(service);
	}

	public void onDestroy() {
		mService.stopForeground(true);
		smarttouch.CloseLowLevelServer();
		mLocalBroadcastManager.unregisterReceiver(mBroadcastReceiver);
		mService.unregisterReceiver(mBroadcastReceiver);
		// try {
		// mService.unregisterReceiver(mBroadcastReceiver);
		// } catch (Exception e) {
		// // TODO: handle exception
		// e.printStackTrace();
		// }

		Log.e(Constants.TAG, "====EventHandler onDestroy===");
		RootUtil.execRootCmd("am force-stop com.android.smarttouch");
	}

	public void onStartCommand(Intent intent, int flags, int startId) {
		setupNotification(mService.getString(R.string.current_status)
				+ mService.getString(R.string.status_wait));
	}

	private void InitSmartTouch() {
		smarttouch = SmartTouch.getInstance(mService);
		smarttouch.OpenLowLevelServer();
	}

	private void Init(Service service) {
		mLocalBroadcastManager = LocalBroadcastManager
				.getInstance(SignalToolClass.mActivity.getApplicationContext());
		// mLocalBroadcastManager = LocalBroadcastManager.getInstance(service);
		InitSmartTouch();

		mBroadcastReceiver = new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				// TODO Auto-generated method stub
				EventHandlerInterface.getInstance(mHandler, mService)
						.doRecevice(context, intent);
			}
		};

		IntentFilter intentFilter = new IntentFilter();
		EventHandlerInterface.getInstance(mHandler, mService).addAction(
				intentFilter);

		mLocalBroadcastManager.registerReceiver(mBroadcastReceiver,
				intentFilter);
		mService.registerReceiver(mBroadcastReceiver, intentFilter);
	}

	// Notification
	private void setupNotification(String text) {
		Intent iTab = new Intent(mService, HomeActivity.class);
		iTab.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP
				| Intent.FLAG_ACTIVITY_SINGLE_TOP);

		PendingIntent pendingIntent = PendingIntent.getActivity(mService, 0,
				iTab, 0);

		RemoteViews contentView = new RemoteViews(mService.getPackageName(),
				R.layout.notification_view);
		contentView.setTextViewText(R.id.notification_title,
				mService.getString(R.string.app_name));
		contentView.setTextViewText(R.id.notification_text, text);
		contentView.setTextViewText(R.id.notification_time,
				DateFormat.getDateEN());

		mNotification = new Notification();
		mNotification.contentView = contentView;
		mNotification.when = System.currentTimeMillis();
		mNotification.tickerText = text;
		mNotification.icon = R.drawable.ic_launcher_icon;
		mNotification.flags = Notification.FLAG_ONGOING_EVENT
				| Notification.FLAG_NO_CLEAR;
		mNotification.contentIntent = pendingIntent;
		mNotification.flags |= Notification.FLAG_NO_CLEAR;

		mService.startForeground(9999, mNotification);
	}

	private void doDeleteFile(String filename) {
		// TODO Auto-generated method stub
		smarttouch.PausePlay();
		try {
			if (0 <= filename.indexOf("/data/data")) {
				// 修改权限
				String[] lists = filename.split("/");
				RootUtil.execRootCmd("chmod -R 777 /data/data" + lists[3] + "/");
			}

			RootUtil.execRootCmd("rm -rf " + filename);
		} catch (Exception e) {
			// TODO: handle exception
			Log.e(Constants.TAG, "====doDeleteFile Error======");
			e.printStackTrace();
		}

		smarttouch.ResumePlay();
	}

	private void doDownloadUrl(String url) {
		Log.e(Constants.TAG, "downloadurl..");
	}

	private void doOpenUlr(String url) {
		Intent intent = new Intent();
		intent.setAction("android.intent.action.VIEW");
		Uri CONTENT_URI_BROWSERS = Uri.parse(url);
		intent.setData(CONTENT_URI_BROWSERS);
		intent.setClassName("com.android.browser",
				"com.android.browser.BrowserActivity");
		intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		mService.getApplicationContext().startActivity(intent);
	}

	// 切换VPN
	public void doSwitchVPN() {
		Log.e(Constants.TAG, "=======doSwitchVPN=========");
	}

	public void doSwitchDevice(String resolution) {
		mResolution = (resolution == null || resolution.isEmpty()) ? "720*1080"
				: resolution;

		smarttouch.PausePlay();

		ThreadUtil.execute(new Runnable() {

			@Override
			public void run() {
				// TODO Auto-generated method stub
				try {
					NetMsgRequestDeviceInfo deviceInfo = new NetMsgRequestDeviceInfo(
							mResolution);

					if (deviceInfo.sendRequest()) {
						String imei = PreferenceUtil.getDefaultPreference(
								mService).getIMEI();
						String imsi = PreferenceUtil.getDefaultPreference(
								mService).getIMSI();
						String iccid = PreferenceUtil.getDefaultPreference(
								mService).getICCID();
						String macAddress = PreferenceUtil
								.getDefaultPreference(mService).getMacAddress();
						String model = PreferenceUtil.getDefaultPreference(
								mService).getModel();
						String device = PreferenceUtil.getDefaultPreference(
								mService).getDevice();

						setDeviceInfo(Constants.IMEI_FILE, imei);
						setDeviceInfo(Constants.IMSI_FILE, imsi);
						setDeviceInfo(Constants.ICCID_FILE, iccid);
						setDeviceInfo(Constants.MAC_ADDRESS_FILE, macAddress);
						setDeviceInfo(Constants.MODEL_FILE, model);
						setDeviceInfo(Constants.DEVICE_FILE, device);
					}
				} catch (Exception e) {
					// TODO: handle exception
					e.printStackTrace();
					Log.e(Constants.TAG, "=====SetDevice Thread Error========");
				} finally {
					smarttouch.ResumePlay();
				}
			}
		});

	}

	private void setLoadScriptDo() {
		PreferenceUtil.getDefaultPreference(mService).setLastScriptName(
				mScriptName);
	}

	private void setInitLoadScript(Intent intent) {
		mScriptName = intent.getStringExtra("ScriptName");
	}

	private void setPlayScriptDo() {
		doPlayScript();
	}

	private void doPlayScript() {
		Log.e(Constants.TAG, "======doPlayScript play=======");
		smarttouch.StartPlay();
	}

	private void setStopScriptDo(long ret) {
		Log.e(Constants.TAG, "=======脚本停止播放======");

		// 接受服务器请求，直接停止的任务
		if (ret == 500) {
			return;
		}

		// 服务器分发的任务，提交结果
		if (PreferenceUtil.getDefaultPreference(mService).getAutoTask()
				&& SignalToolClass.IS_SERVER_TASK) {
			if (mIsErrorStop) {
				EventBus.getDefault().post(
						new StatusEvent(StatusEvent.STATUS_STOP, String
								.valueOf(TaskRunEvent.RESULT_FAILED)));
			} else {
				EventBus.getDefault().post(
						new StatusEvent(StatusEvent.STATUS_STOP, String
								.valueOf(TaskRunEvent.RESULT_SUCCESS)));
			}
		} else {
			Log.e(Constants.TAG, "========非服务器分发任务========");
		}

		if (ret == 100) {
			mScriptRunCnt++;
		} else if (ret == 200) {// 手动停止脚本
			PreferenceUtil.getDefaultPreference(mService).setAutoTask(false);
		}
	}

	private void setDeviceInfo(String key, String info) {
		String cmd = "echo '" + info + "'>" + Constants.DEVICEINFO_PATH + key;
		RootUtil.execRootCmd(cmd);
	}
}
