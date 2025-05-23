package uz.hayatbank.api.transport.result;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.transport.GenericResult;

@EqualsAndHashCode(callSuper = true)
@Data
public class TokenResult extends GenericResult {
    private String auth_token;
    private String refresh_token;
    private String type = "Bearer";
    private Integer expire_seconds = 60 * 60 * 24;
}
