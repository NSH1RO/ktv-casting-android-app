package zju.bangdream.ktv.casting.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp

@Composable
fun MediaUrlModeSelector(direct: Boolean, onDirectChange: (Boolean) -> Unit) {
    Column(modifier = Modifier.fillMaxWidth().selectableGroup()) {
        Text("媒体传输方式", style = MaterialTheme.typography.titleSmall)
        listOf(
            false to ("反向代理（默认）" to "由手机转发媒体，支持缓存、定位和双轨混流"),
            true to ("传原链接" to "设备直接访问源站，需支持链接协议、媒体格式及鉴权")
        ).forEach { (value, copy) ->
            Row(
                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                    .selectable(selected = direct == value, role = Role.RadioButton,
                        onClick = { onDirectChange(value) })
                    .padding(vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(selected = direct == value, onClick = null)
                Spacer(Modifier.width(8.dp))
                Column(Modifier.weight(1f)) {
                    Text(copy.first, style = MaterialTheme.typography.bodyMedium)
                    Text(copy.second, style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        Text("选择会保存，重新连接 DLNA 设备后生效。",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
